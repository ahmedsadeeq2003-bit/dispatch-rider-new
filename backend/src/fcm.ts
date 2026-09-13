import { GoogleAuth } from 'google-auth-library';
import { config } from './config';

let cachedAuth: GoogleAuth | null = null;

function getAuth(): GoogleAuth {
  if (cachedAuth) return cachedAuth;
  const credentials = JSON.parse(config.fcmServiceAccountJson);
  cachedAuth = new GoogleAuth({
    credentials,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });
  return cachedAuth;
}

async function getAccessToken(): Promise<string> {
  const client = await getAuth().getClient();
  const { token } = await client.getAccessToken();
  if (!token) throw new Error('Failed to obtain FCM access token');
  return token;
}

export interface PushMessage {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Sends one push message via FCM HTTP v1. The v1 API has no true multicast —
 * callers send a batch by looping (see sendPushToMany). Failures for
 * individual (possibly stale) tokens are swallowed and logged, not thrown,
 * so one bad token doesn't block the rest of a fan-out.
 */
export async function sendPush(msg: PushMessage): Promise<void> {
  const accessToken = await getAccessToken();
  const url = `https://fcm.googleapis.com/v1/projects/${config.fcmProjectId}/messages:send`;

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json; UTF-8',
    },
    body: JSON.stringify({
      message: {
        token: msg.token,
        notification: { title: msg.title, body: msg.body },
        data: msg.data,
      },
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    console.error(`FCM send failed (${res.status}) for token ${msg.token.slice(0, 12)}…: ${text}`);
  }
}

export async function sendPushToMany(
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  await Promise.all(
    tokens
      .filter((t) => !!t)
      .map((token) => sendPush({ token, title, body, data }).catch((e) => {
        console.error('sendPush error:', e);
      })),
  );
}
