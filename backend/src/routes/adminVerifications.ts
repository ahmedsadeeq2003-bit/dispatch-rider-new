import { Router } from 'express';
import { z } from 'zod';
import { requireUser, requireAdmin } from '../middleware/auth';
import { supabaseAdmin } from '../supabaseAdmin';

export const adminVerificationsRouter = Router();

const reviewSchema = z.object({
  action: z.enum(['approve', 'reject']),
});

adminVerificationsRouter.post(
  '/admin/verifications/:id',
  requireUser,
  requireAdmin,
  async (req, res) => {
    const parsed = reviewSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: parsed.error.flatten() });
    }

    const status = parsed.data.action === 'approve' ? 'approved' : 'rejected';

    const { data, error } = await supabaseAdmin
      .from('rider_verifications')
      .update({
        status,
        reviewed_at: new Date().toISOString(),
        reviewed_by: req.userId,
      })
      .eq('id', req.params.id)
      .select()
      .maybeSingle();

    if (error) return res.status(500).json({ error: error.message });
    if (!data) return res.status(404).json({ error: 'verification not found' });

    res.json({ ok: true, verification: data });
  },
);

adminVerificationsRouter.get(
  '/admin/verifications',
  requireUser,
  requireAdmin,
  async (req, res) => {
    const status = typeof req.query.status === 'string' ? req.query.status : 'pending';
    const { data, error } = await supabaseAdmin
      .from('rider_verifications')
      .select('*, profiles!rider_verifications_rider_id_fkey(full_name, phone_number)')
      .eq('status', status)
      .order('submitted_at', { ascending: true });

    if (error) return res.status(500).json({ error: error.message });
    res.json({ verifications: data });
  },
);
