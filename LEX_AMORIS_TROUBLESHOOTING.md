# Lex Amoris - Troubleshooting Workflow

**Document Version:** 1.0.0  
**Last Updated:** 2026-01-11  
**Application:** Lex Amoris - Sempre in Costante

---

## Table of Contents

1. [Quick Diagnostic Checklist](#quick-diagnostic-checklist)
2. [Animation Issues](#animation-issues)
3. [Growth Function Issues](#growth-function-issues)
4. [Shield Alert Issues](#shield-alert-issues)
5. [PWA Installation Issues](#pwa-installation-issues)
6. [Performance Issues](#performance-issues)
7. [Browser Compatibility Issues](#browser-compatibility-issues)
8. [IPFS Deployment Issues](#ipfs-deployment-issues)
9. [Advanced Diagnostics](#advanced-diagnostics)

---

## Quick Diagnostic Checklist

Before proceeding with detailed troubleshooting, verify these basics:

- [ ] Files are served over HTTPS (required for PWA features)
- [ ] Browser DevTools console shows no errors
- [ ] Page fully loads (no 404 or network errors)
- [ ] JavaScript is enabled in browser
- [ ] Browser is up to date (Chrome 120+, Firefox 121+, Safari 17+)
- [ ] No browser extensions blocking content

**Quick Test Commands:**

Open browser console (F12) and run:
```javascript
// Check if page is loaded
console.log('Lex Amoris loaded:', document.title);

// Check state object
console.log('Application state:', state);

// Check configuration
console.log('Configuration:', CONFIG);
```

---

## Animation Issues

### Problem 1: Pulsating animation not visible

**Symptoms:**
- Center pulse circle is static
- No ring animation appears
- Animation appears frozen

**Root Causes:**
1. CSS animations disabled in browser
2. Reduced motion preference enabled
3. Animation paused programmatically
4. CSS not loading properly

**Diagnostic Steps:**

1. **Check CSS animation support:**
```javascript
// In browser console
const el = document.querySelector('.resonance-pulse');
console.log('Animation:', window.getComputedStyle(el).animation);
```

2. **Check animation state:**
```javascript
console.log('Pulse active:', state.pulseActive);
console.log('Animation play state:', 
  window.getComputedStyle(document.querySelector('.resonance-pulse')).animationPlayState
);
```

3. **Check reduced motion:**
```javascript
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
console.log('Reduced motion:', prefersReducedMotion.matches);
```

**Solutions:**

**Solution 1:** Re-enable animation programmatically
```javascript
// In browser console
const pulse = document.querySelector('.resonance-pulse');
const ring = document.querySelector('.resonance-ring');
pulse.style.animationPlayState = 'running';
ring.style.animationPlayState = 'running';
```

**Solution 2:** Check browser settings
- Chrome: Settings → Accessibility → Remove "Prefers reduced motion"
- Firefox: about:config → ui.prefersReducedMotion → 0
- Safari: System Preferences → Accessibility → Display → Reduce motion (off)

**Solution 3:** Force toggle
```javascript
togglePulse(); // Pause
togglePulse(); // Resume
```

---

### Problem 2: Animation is choppy or stuttering

**Symptoms:**
- Animation skips frames
- Not smooth 60fps
- Visual jerkiness

**Root Causes:**
1. High CPU usage from other processes
2. Browser hardware acceleration disabled
3. Too many browser tabs open
4. Low-end device limitations

**Diagnostic Steps:**

1. **Check frame rate:**
```javascript
let lastTime = performance.now();
let frameCount = 0;
function checkFPS() {
  frameCount++;
  const now = performance.now();
  if (now >= lastTime + 1000) {
    console.log('FPS:', frameCount);
    frameCount = 0;
    lastTime = now;
  }
  requestAnimationFrame(checkFPS);
}
checkFPS();
```

2. **Check GPU acceleration:**
- Chrome: chrome://gpu
- Firefox: about:support → Graphics
- Look for "Hardware Acceleration: Enabled"

**Solutions:**

**Solution 1:** Enable hardware acceleration
- Chrome: Settings → System → Use hardware acceleration
- Firefox: Settings → Performance → Use hardware acceleration
- Edge: Settings → System → Use hardware acceleration

**Solution 2:** Reduce system load
- Close unnecessary tabs
- Close other applications
- Disable browser extensions temporarily

**Solution 3:** Adjust animation complexity
```javascript
// Reduce animation frequency (in lexamoris.html)
// Change animation duration from 3s to 5s for smoother motion
```

---

## Growth Function Issues

### Problem 3: Growth rate calculation seems incorrect

**Symptoms:**
- Numbers don't match expected exponential growth
- Growth seems too fast or too slow
- Display shows unexpected values

**Root Causes:**
1. Incorrect iteration count
2. Floating-point precision issues
3. Function called too frequently
4. Cap reached prematurely

**Diagnostic Steps:**

1. **Verify function logic:**
```javascript
// Manual calculation test
const testIterations = 100;
const expected = 1.0 * Math.pow(1.01, testIterations);
const actual = calculateGrowthRate(testIterations);
console.log('Expected:', expected);
console.log('Actual:', actual);
console.log('Match:', Math.abs(expected - actual) < 0.001);
```

2. **Check iteration count:**
```javascript
console.log('Current iterations:', state.iterationCount);
console.log('Growth rate:', state.growthRate);
```

3. **Test with known values:**
```javascript
// Known test cases
console.log('10 iterations:', calculateGrowthRate(10));   // Should be ~1.105
console.log('100 iterations:', calculateGrowthRate(100)); // Should be ~2.705
console.log('500 iterations:', calculateGrowthRate(500)); // Should be 100.000 (capped)
```

**Solutions:**

**Solution 1:** Reset and verify
```javascript
resetMetrics();
// Wait 10 seconds and check
setTimeout(() => console.log('After 10s:', state.growthRate), 10000);
```

**Solution 2:** Adjust cap if needed
```javascript
// If you need higher cap, modify in source:
// const maxIterations = 2000; // Instead of 1000
```

**Solution 3:** Check update interval
```javascript
console.log('Update interval:', CONFIG.metricsUpdateInterval, 'ms');
// Should be 1000ms (1 second)
```

---

### Problem 4: Growth rate causing performance issues

**Symptoms:**
- Page becomes slow
- Browser tab uses high CPU
- Metrics stop updating

**Root Causes:**
1. Update interval too short
2. Calculation too complex
3. Memory leak in update loop
4. Too many console logs

**Diagnostic Steps:**

1. **Check CPU usage:**
- Chrome Task Manager: Shift+Esc
- Look for tab CPU percentage
- Should be <5% normally

2. **Profile performance:**
```javascript
// Start profiling
console.profile('Growth Function');
for (let i = 0; i < 1000; i++) {
  calculateGrowthRate(i);
}
console.profileEnd('Growth Function');
```

**Solutions:**

**Solution 1:** Increase update interval
```javascript
// Modify CONFIG in source if needed
// metricsUpdateInterval: 2000 // Instead of 1000
```

**Solution 2:** Disable console logging
```javascript
// Comment out console.log statements in production
```

**Solution 3:** Pause metrics temporarily
```javascript
state.pulseActive = false;
togglePulse(); // This will pause updates
```

---

## Shield Alert Issues

### Problem 5: Shield alerts not appearing

**Symptoms:**
- Clicking "Test Shield Alert" does nothing
- No visual change
- No console messages
- No browser notification

**Root Causes:**
1. JavaScript error in function
2. Notification permission denied
3. DOM elements not found
4. Event listener not attached

**Diagnostic Steps:**

1. **Check function exists:**
```javascript
console.log('Function exists:', typeof testShieldAlert === 'function');
```

2. **Manually trigger:**
```javascript
testShieldAlert();
```

3. **Check DOM elements:**
```javascript
console.log('Shield status:', document.getElementById('shield-status'));
console.log('Shield message:', document.getElementById('shield-message'));
```

4. **Check notification permission:**
```javascript
console.log('Notification permission:', Notification.permission);
```

**Solutions:**

**Solution 1:** Request notification permission
```javascript
if (Notification.permission === 'default') {
  Notification.requestPermission().then(permission => {
    console.log('Permission:', permission);
  });
}
```

**Solution 2:** Check browser console for errors
- Press F12
- Look for red error messages
- Address any JavaScript errors

**Solution 3:** Manually update shield status
```javascript
const shieldStatus = document.getElementById('shield-status');
shieldStatus.classList.add('alert');
document.getElementById('shield-message').textContent = '⚠️ Test Alert';
```

---

### Problem 6: Shield alerts don't restore automatically

**Symptoms:**
- Alert stays in "red" state
- Doesn't return to normal after 5 seconds
- Manual intervention needed

**Root Causes:**
1. setTimeout not executing
2. State not updating
3. JavaScript error during restore
4. Page lost focus

**Diagnostic Steps:**

1. **Check timeout execution:**
```javascript
console.log('Testing timeout...');
setTimeout(() => console.log('Timeout works!'), 1000);
```

2. **Check state:**
```javascript
console.log('Shield active:', state.shieldActive);
```

**Solutions:**

**Solution 1:** Manually restore
```javascript
state.shieldActive = true;
document.getElementById('shield-status').classList.remove('alert');
document.getElementById('shield-message').textContent = '🛡️ Red Shield: Active & Secure';
```

**Solution 2:** Reload page
```javascript
location.reload();
```

---

## PWA Installation Issues

### Problem 7: Install prompt doesn't appear

**Symptoms:**
- No "Install app" button in browser
- Can't add to home screen
- PWA features not working

**Root Causes:**
1. Not served over HTTPS
2. Manifest not loading
3. Service worker issues (if implemented)
4. Browser doesn't support PWA

**Diagnostic Steps:**

1. **Check HTTPS:**
```javascript
console.log('Protocol:', window.location.protocol);
// Should be 'https:' or 'file:' for local testing
```

2. **Check manifest loading:**
```javascript
// In Chrome DevTools: Application → Manifest
// Should show all manifest fields
```

3. **Validate manifest:**
```javascript
fetch('manifest.json')
  .then(r => r.json())
  .then(m => console.log('Manifest:', m))
  .catch(e => console.error('Manifest error:', e));
```

4. **Check browser support:**
- Chrome/Edge: Full support
- Firefox: Partial support
- Safari: Add to home screen only

**Solutions:**

**Solution 1:** Serve over HTTPS
- Use a local HTTPS server
- Deploy to HTTPS hosting
- Use ngrok for testing: `ngrok http 8080`

**Solution 2:** Verify manifest path
```javascript
const link = document.querySelector('link[rel="manifest"]');
console.log('Manifest link:', link ? link.href : 'Not found');
```

**Solution 3:** Manual installation
- Chrome: Menu → Install Lex Amoris
- Firefox: Menu → Add to Home Screen
- Safari: Share → Add to Home Screen

---

## Performance Issues

### Problem 8: Page loads slowly

**Symptoms:**
- Initial page load takes >2 seconds
- White screen before content appears
- Slow responsiveness

**Root Causes:**
1. Large file size
2. Slow network connection
3. Unoptimized images
4. JavaScript blocking rendering

**Diagnostic Steps:**

1. **Check file sizes:**
```bash
ls -lh lexamoris.html manifest.json
```

2. **Check load time:**
```javascript
window.addEventListener('load', () => {
  const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
  console.log('Load time:', loadTime, 'ms');
});
```

3. **Check network tab:**
- Open DevTools → Network
- Reload page
- Check waterfall for slow resources

**Solutions:**

**Solution 1:** Enable caching
```html
<!-- Add to HTML head -->
<meta http-equiv="cache-control" content="max-age=3600">
```

**Solution 2:** Use CDN for external resources
- Already using inline styles and scripts
- No external dependencies to optimize

**Solution 3:** Minimize inline SVGs
- Convert large SVG data URIs to external files if needed

---

## Browser Compatibility Issues

### Problem 9: Features not working in specific browser

**Symptoms:**
- Works in Chrome but not Firefox
- Safari shows errors
- Old browser completely broken

**Root Causes:**
1. Browser doesn't support modern features
2. Vendor prefix needed
3. Polyfill required
4. Browser bugs

**Diagnostic Steps:**

1. **Check browser version:**
```javascript
console.log('User agent:', navigator.userAgent);
```

2. **Check feature support:**
```javascript
console.log('Notification support:', 'Notification' in window);
console.log('Promise support:', 'Promise' in window);
console.log('Arrow functions:', (() => true)());
```

**Solutions:**

**Solution 1:** Update browser
- Chrome: Menu → Help → About Chrome
- Firefox: Menu → Help → About Firefox
- Safari: App Store → Updates

**Solution 2:** Use compatibility mode
- Disable advanced features in older browsers
- Graceful degradation already implemented

**Solution 3:** Add polyfills (if needed)
```html
<!-- Add before closing </head> -->
<script src="https://polyfill.io/v3/polyfill.min.js"></script>
```

---

## IPFS Deployment Issues

### Problem 10: IPFS links not working

**Symptoms:**
- IPFS links return 404
- Slow loading from IPFS gateway
- Content not found

**Root Causes:**
1. Content not pinned
2. Wrong CID
3. Gateway timeout
4. IPFS gateway issues

**Diagnostic Steps:**

1. **Verify CID:**
```bash
ipfs cat <CID>
```

2. **Check gateway:**
```bash
curl https://ipfs.io/ipfs/<CID>
```

3. **Test different gateways:**
- https://ipfs.io/ipfs/CID
- https://gateway.pinata.cloud/ipfs/CID
- https://cloudflare-ipfs.com/ipfs/CID

**Solutions:**

**Solution 1:** Re-add to IPFS
```bash
ipfs add lexamoris.html manifest.json
ipfs pin add <CID>
```

**Solution 2:** Use alternative gateway
```javascript
// Update manifest.json with working gateway
```

**Solution 3:** Verify pinning service
```bash
ipfs pin ls | grep <CID>
```

---

## Advanced Diagnostics

### System Health Check Script

Run this comprehensive diagnostic:

```javascript
// Lex Amoris Health Check
console.log('=== LEX AMORIS HEALTH CHECK ===\n');

// 1. Environment
console.log('1. ENVIRONMENT');
console.log('  Protocol:', window.location.protocol);
console.log('  Host:', window.location.host);
console.log('  User Agent:', navigator.userAgent);
console.log('  Online:', navigator.onLine);
console.log('');

// 2. Core Objects
console.log('2. CORE OBJECTS');
console.log('  CONFIG exists:', typeof CONFIG !== 'undefined');
console.log('  state exists:', typeof state !== 'undefined');
console.log('  Pulse active:', state ? state.pulseActive : 'N/A');
console.log('  Shield active:', state ? state.shieldActive : 'N/A');
console.log('');

// 3. DOM Elements
console.log('3. DOM ELEMENTS');
const elements = [
  'growth-rate',
  'resonance-freq',
  'sroi',
  'pulse-duration',
  'shield-status',
  'shield-message'
];
elements.forEach(id => {
  console.log(`  #${id}:`, document.getElementById(id) ? '✓' : '✗');
});
console.log('');

// 4. Functions
console.log('4. FUNCTIONS');
const functions = [
  'calculateGrowthRate',
  'updateMetrics',
  'testShieldAlert',
  'resetMetrics',
  'togglePulse'
];
functions.forEach(fn => {
  console.log(`  ${fn}:`, typeof window[fn] === 'function' ? '✓' : '✗');
});
console.log('');

// 5. Animations
console.log('5. ANIMATIONS');
const pulse = document.querySelector('.resonance-pulse');
const ring = document.querySelector('.resonance-ring');
console.log('  Pulse element:', pulse ? '✓' : '✗');
console.log('  Ring element:', ring ? '✓' : '✗');
if (pulse) {
  const style = window.getComputedStyle(pulse);
  console.log('  Animation:', style.animation || 'none');
  console.log('  Play state:', style.animationPlayState);
}
console.log('');

// 6. Performance
console.log('6. PERFORMANCE');
if (performance.timing) {
  const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
  console.log('  Page load:', loadTime, 'ms');
  console.log('  DOM ready:', performance.timing.domContentLoadedEventEnd - performance.timing.navigationStart, 'ms');
}
console.log('  Memory:', performance.memory ? `${(performance.memory.usedJSHeapSize / 1048576).toFixed(2)} MB` : 'N/A');
console.log('');

// 7. PWA
console.log('7. PWA FEATURES');
console.log('  Manifest link:', document.querySelector('link[rel="manifest"]') ? '✓' : '✗');
console.log('  HTTPS:', window.location.protocol === 'https:' ? '✓' : '✗');
console.log('  Notification API:', 'Notification' in window ? '✓' : '✗');
console.log('  Notification perm:', Notification.permission);
console.log('');

console.log('=== HEALTH CHECK COMPLETE ===');
```

---

## Contact and Support

For additional assistance:

1. **Check console logs** - Most issues show warnings/errors
2. **Review this troubleshooting guide** - Common issues covered
3. **Test in different browser** - Isolate browser-specific issues
4. **Clear cache and reload** - Resolves many caching issues
5. **Check IPFS status** - Verify gateway availability

---

**Document Status:** Production Ready  
**Last Updated:** 2026-01-11  
**Version:** 1.0.0  
**Sempre in Costante**
