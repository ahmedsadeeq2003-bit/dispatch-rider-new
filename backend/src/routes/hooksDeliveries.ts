import { Router } from 'express';
import { supabaseAdmin } from '../supabaseAdmin';
import { sendPushToMany } from '../fcm';
import { verifyWebhookSecret } from '../middleware/verifyWebhookSecret';

export const hooksDeliveriesRouter = Router();

interface DeliveryWebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  table: string;
  record: Record<string, any> | null;
  old_record: Record<string, any> | null;
}

/**
 * Receives Supabase Database Webhook calls for the `deliveries` table.
 * Configure in Supabase Dashboard -> Database -> Webhooks (or via a
 * pg_net-based trigger) to POST here on INSERT and UPDATE, with header
 * `x-webhook-secret: <WEBHOOK_SHARED_SECRET>`.
 */
hooksDeliveriesRouter.post('/hooks/deliveries', verifyWebhookSecret, async (req, res) => {
  const payload = req.body as DeliveryWebhookPayload;
  const record = payload.record;
  if (!record) return res.status(204).end();

  try {
    if (payload.type === 'INSERT' && record.status === 'pending') {
      await notifyNearbyRiders(record.id, record.pickup_address, record.dropoff_address);
    } else if (
      payload.type === 'UPDATE' &&
      record.status === 'accepted' &&
      payload.old_record?.status === 'pending'
    ) {
      await notifyClientAccepted(record.id);
    }
    res.status(200).json({ ok: true });
  } catch (e) {
    console.error('hooks/deliveries error:', e);
    // Respond 200 anyway — Supabase webhooks don't meaningfully retry, and
    // we don't want a push failure to look like a delivery-creation failure.
    res.status(200).json({ ok: false, error: String(e) });
  }
});

async function notifyNearbyRiders(deliveryId: string, pickup: string, destination: string) {
  const { data: riders, error } = await supabaseAdmin.rpc('find_nearby_riders', {
    p_delivery_id: deliveryId,
    p_radius_m: 15000,
    p_limit: 5,
  });
  if (error) throw error;

  const tokens = (riders ?? [])
    .map((r: any) => r.fcm_token as string | null)
    .filter((t: string | null): t is string => !!t);

  if (tokens.length === 0) {
    console.log(`No online riders with a location within range for delivery ${deliveryId}`);
    return;
  }

  await sendPushToMany(
    tokens,
    'New Delivery Request!',
    `Pickup: ${pickup}\nDestination: ${destination}`,
    { type: 'new_delivery', deliveryId },
  );
}

interface NotifyTargets {
  client_id: string;
  client_token: string | null;
  rider_id: string | null;
  rider_token: string | null;
}

async function notifyClientAccepted(deliveryId: string) {
  const { data, error } = await supabaseAdmin
    .rpc('get_delivery_notify_targets', { p_delivery_id: deliveryId })
    .maybeSingle<NotifyTargets>();
  if (error) throw error;
  if (!data?.client_token) return;

  await sendPushToMany(
    [data.client_token],
    'Rider found!',
    'A rider has accepted your delivery request.',
    { type: 'delivery_accepted', deliveryId },
  );
}
