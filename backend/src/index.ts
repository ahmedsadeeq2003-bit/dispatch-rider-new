import express from 'express';
import { config } from './config';
import { healthRouter } from './routes/health';
import { hooksDeliveriesRouter } from './routes/hooksDeliveries';
import { adminVerificationsRouter } from './routes/adminVerifications';
import { adminCompaniesRouter } from './routes/adminCompanies';
import { ratingsRouter } from './routes/ratings';

const app = express();
app.use(express.json());

app.use(healthRouter);
app.use(hooksDeliveriesRouter);
app.use(adminVerificationsRouter);
app.use(adminCompaniesRouter);
app.use(ratingsRouter);

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'internal server error' });
});

app.listen(config.port, () => {
  console.log(`dispatch-rider-backend listening on :${config.port}`);
});
