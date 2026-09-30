let sessionInvalidationHandler: Function | null = null;

export function setSessionInvalidationHandler(handler: Function | null): void {
  sessionInvalidationHandler = handler;
}

export function clearSessionInvalidationHandler(): void {
  sessionInvalidationHandler = null;
}

export function notifySessionInvalidated(message: string): void {
  const fallbackMessage = '登录已过期，请重新登录。';
  const notice = message.trim().length > 0 ? message.trim() : fallbackMessage;
  if (sessionInvalidationHandler !== null) {
    sessionInvalidationHandler(notice);
  }
}
