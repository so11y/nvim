import { setTimeout as delay } from 'node:timers/promises';

export async function waitFor(read, ready, message) {
  const deadline = Date.now() + 5000;
  let state;
  do {
    state = await read();
    if (ready(state)) return state;
    await delay(20);
  } while (Date.now() < deadline);
  throw new Error(message + ': ' + JSON.stringify(state));
}
