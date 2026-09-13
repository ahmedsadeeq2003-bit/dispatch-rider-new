function required(name: string): string {
  const v = process.env[name];
  if (!v || v.trim().length === 0) {
    throw new Error(`Missing required env var: ${name}`);
  }
  return v;
}

export const config = {
  port: Number(process.env.PORT ?? 8080),
  supabaseUrl: required('SUPABASE_URL'),
  supabaseServiceRoleKey: required('SUPABASE_SERVICE_ROLE_KEY'),
  webhookSharedSecret: required('WEBHOOK_SHARED_SECRET'),
  fcmProjectId: required('FCM_PROJECT_ID'),
  fcmServiceAccountJson: required('FCM_SERVICE_ACCOUNT_JSON'),
};
