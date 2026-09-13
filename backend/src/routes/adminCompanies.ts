import { Router } from 'express';
import { z } from 'zod';
import { requireUser, requireAdmin } from '../middleware/auth';
import { supabaseAdmin } from '../supabaseAdmin';

export const adminCompaniesRouter = Router();

const createCompanySchema = z.object({
  code: z.string().min(2).max(32),
  name: z.string().min(1),
  plan: z.string().default('free'),
});

adminCompaniesRouter.post('/admin/companies', requireUser, requireAdmin, async (req, res) => {
  const parsed = createCompanySchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { data, error } = await supabaseAdmin
    .from('companies')
    .insert(parsed.data)
    .select()
    .single();

  if (error) return res.status(400).json({ error: error.message });
  res.status(201).json({ company: data });
});

adminCompaniesRouter.get('/admin/companies', requireUser, requireAdmin, async (_req, res) => {
  const { data, error } = await supabaseAdmin
    .from('companies')
    .select()
    .order('created_at', { ascending: false });

  if (error) return res.status(500).json({ error: error.message });
  res.json({ companies: data });
});
