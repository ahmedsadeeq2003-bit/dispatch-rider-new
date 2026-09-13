import { Request, Response, NextFunction } from 'express';
import { config } from '../config';

/** Guards routes that only the Supabase Database Webhook should call. */
export function verifyWebhookSecret(req: Request, res: Response, next: NextFunction) {
  const provided = req.header('x-webhook-secret');
  if (!provided || provided !== config.webhookSharedSecret) {
    return res.status(401).json({ error: 'invalid webhook secret' });
  }
  next();
}
