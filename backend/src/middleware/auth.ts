import { Request, Response, NextFunction } from 'express';
import { getUserFromToken, getProfile } from '../supabaseAdmin';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      userId?: string;
      profile?: { id: string; role: string; company_id: string | null };
    }
  }
}

function bearerToken(req: Request): string | null {
  const header = req.header('authorization');
  if (!header?.startsWith('Bearer ')) return null;
  return header.slice('Bearer '.length);
}

/** Requires a valid Supabase user session; attaches req.userId + req.profile. */
export async function requireUser(req: Request, res: Response, next: NextFunction) {
  const token = bearerToken(req);
  if (!token) return res.status(401).json({ error: 'missing bearer token' });

  const user = await getUserFromToken(token);
  if (!user) return res.status(401).json({ error: 'invalid or expired token' });

  const profile = await getProfile(user.id);
  if (!profile) return res.status(404).json({ error: 'profile not found' });

  req.userId = user.id;
  req.profile = profile as { id: string; role: string; company_id: string | null };
  next();
}

/** Requires the caller's profile to have role = 'admin'. Call after requireUser. */
export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  if (req.profile?.role !== 'admin') {
    return res.status(403).json({ error: 'admin role required' });
  }
  next();
}
