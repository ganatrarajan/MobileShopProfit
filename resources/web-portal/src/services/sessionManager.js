import { authApi } from '@/api/endpoints';

const INACTIVITY_TIMEOUT_MS = 30 * 60 * 1000; // 30 minutes
const CHECK_INTERVAL_MS = 15 * 1000;          // Check every 15s
const HEARTBEAT_INTERVAL_MS = 60 * 1000;      // Ping server every 60s
const THROTTLE_WRITE_MS = 5 * 1000;           // Throttle storage writes to every 5s

let lastRecordedWrite = 0;
let checkTimer = null;
let heartbeatTimer = null;
let isInitialized = false;

/**
 * Record user activity timestamp in localStorage so it synchronizes across all browser tabs.
 */
export function recordActivity() {
  const now = Date.now();
  if (now - lastRecordedWrite > THROTTLE_WRITE_MS) {
    lastRecordedWrite = now;
    try {
      localStorage.setItem('mr_portal_last_active', now.toString());
    } catch {
      // Storage unavailable / private mode quota
    }
  }
}

/**
 * Check if the user has been inactive for 30 minutes.
 */
export function isSessionExpiredDueToInactivity() {
  const token = localStorage.getItem('auth_token');
  if (!token) return false;

  const rawLastActive = localStorage.getItem('mr_portal_last_active');
  if (!rawLastActive) {
    // If not set yet, initialize it now
    recordActivity();
    return false;
  }

  const lastActive = parseInt(rawLastActive, 10);
  if (isNaN(lastActive) || lastActive <= 0) return false;

  return Date.now() - lastActive >= INACTIVITY_TIMEOUT_MS;
}

/**
 * Execute logout with a persistent notice displayed on the login page.
 */
export function terminateSession(reason, customMessage) {
  stopSessionManager();

  const messages = {
    inactivity: 'You have been automatically logged out due to 30 minutes of inactivity. Please enter your credentials to resume.',
    concurrent: 'Your session has ended because this account was logged into from another device or browser. Only one active login is permitted at a time.',
    expired: 'Your session has expired. Please sign in again.',
  };

  const message = customMessage || messages[reason] || messages.expired;

  try {
    sessionStorage.setItem('portal_auth_notice', JSON.stringify({ type: reason, message }));
  } catch {
    // ignore
  }

  // Clear credentials
  localStorage.removeItem('auth_token');
  localStorage.removeItem('user');
  localStorage.removeItem('shop');
  localStorage.removeItem('mr_portal_last_active');

  // Redirect to login page
  if (typeof window !== 'undefined' && !window.location.pathname.includes('/login')) {
    window.location.href = `/portal/login?reason=${encodeURIComponent(reason)}`;
  }
}

/**
 * Perform single-session heartbeat check.
 * If another person logged in on the same account, backend revoked the token and returns 401.
 */
async function performSessionCheck() {
  const token = localStorage.getItem('auth_token');
  if (!token) return;

  // Don't ping if tab is hidden / browser minimized to save battery & network
  if (typeof document !== 'undefined' && document.hidden) return;

  try {
    await authApi.sessionCheck();
  } catch (err) {
    if (err.response?.status === 401) {
      terminateSession(
        'concurrent',
        'You have been logged out because this account was logged into from another device. Only 1 active person is permitted at a time.'
      );
    }
  }
}

/**
 * Start session monitor (tracks user activity, inactivity timer, and concurrent login ping).
 */
export function initSessionManager() {
  if (isInitialized || typeof window === 'undefined') return;
  isInitialized = true;

  // Initialize activity timestamp
  const rawLastActive = localStorage.getItem('mr_portal_last_active');
  if (!rawLastActive) {
    recordActivity();
  }

  // Activity events
  const activityEvents = ['mousedown', 'keydown', 'touchstart', 'scroll', 'click'];
  activityEvents.forEach((event) => {
    window.addEventListener(event, recordActivity, { passive: true });
  });

  // 1. Inactivity check interval (runs every 15s)
  checkTimer = setInterval(() => {
    if (isSessionExpiredDueToInactivity()) {
      terminateSession(
        'inactivity',
        'You have been automatically logged out due to 30 minutes of inactivity. Please sign in again to continue.'
      );
    }
  }, CHECK_INTERVAL_MS);

  // 2. Concurrent session heartbeat (runs every 60s)
  heartbeatTimer = setInterval(() => {
    performSessionCheck();
  }, HEARTBEAT_INTERVAL_MS);
}

/**
 * Stop session monitor.
 */
export function stopSessionManager() {
  if (checkTimer) {
    clearInterval(checkTimer);
    checkTimer = null;
  }
  if (heartbeatTimer) {
    clearInterval(heartbeatTimer);
    heartbeatTimer = null;
  }
  isInitialized = false;
}
