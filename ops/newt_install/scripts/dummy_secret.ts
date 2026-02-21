// dummy_secret.ts
// This tiny TypeScript script demonstrates reading a secret from an environment variable.
// In the dev container you can set DUMMY_SECRET in a .env file (which should be git‑ignored).

if (!process.env.DUMMY_SECRET) {
    console.error('❌ DUMMY_SECRET is not set');
    process.exit(1);
}

console.log(`🔑 The dummy secret is: ${process.env.DUMMY_SECRET}`);
