import { Router } from 'express';
import { z } from 'zod';
import { requireUser } from '../middleware/auth';
import { supabaseAdmin } from '../supabaseAdmin';

export const ratingsRouter = Router();

const rateSchema = z.object({
  stars: z.number().min(1).max(5),
});

/**
 * A client rates the rider of a completed delivery. This is the only caller
 * of apply_rider_rating() — that RPC is service_role-only precisely so this
 * endpoint can enforce "only the client of a COMPLETED, not-yet-rated
 * delivery may rate, and only once" before touching it.
 */
ratingsRouter.post('/deliveries/:id/rating', requireUser, async (req, res) => {
  const parsed = rateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { data: delivery, error: fetchError } = await supabaseAdmin
    .from('deliveries')
    .select('id, client_id, rider_id, status, rating_submitted')
    .eq('id', req.params.id)
    .maybeSingle();

  if (fetchError) return res.status(500).json({ error: fetchError.message });
  if (!delivery) return res.status(404).json({ error: 'delivery not found' });
  if (delivery.client_id !== req.userId) {
    return res.status(403).json({ error: 'only the client of this delivery may rate it' });
  }
  if (delivery.status !== 'completed') {
    return res.status(409).json({ error: 'delivery is not completed yet' });
  }
  if (delivery.rating_submitted) {
    return res.status(409).json({ error: 'this delivery has already been rated' });
  }
  if (!delivery.rider_id) {
    return res.status(409).json({ error: 'delivery has no assigned rider' });
  }

  const { error: rpcError } = await supabaseAdmin.rpc('apply_rider_rating', {
    p_rider: delivery.rider_id,
    p_stars: parsed.data.stars,
  });
  if (rpcError) return res.status(500).json({ error: rpcError.message });

  const { error: markError } = await supabaseAdmin
    .from('deliveries')
    .update({ rating_submitted: true })
    .eq('id', delivery.id);
  if (markError) return res.status(500).json({ error: markError.message });

  res.json({ ok: true });
});
