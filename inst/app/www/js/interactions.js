/**
 * zen-interactions.js - Client-side interactions for Spiralizer
 *
 * Handles custom Shiny message handlers, keyboard shortcuts,
 * and UI enhancements for the zen mode interface.
 */

(function() {
  'use strict';

  // ═══════════════════════════════════════════════════════════════════════
  // SHINY MESSAGE HANDLERS
  // ═══════════════════════════════════════════════════════════════════════

  // Show loading overlay
  Shiny.addCustomMessageHandler('showLoading', function(message) {
    const overlay = document.getElementById(message.id);
    if (overlay) {
      overlay.style.display = 'flex';
    }
  });

  // Hide loading overlay
  Shiny.addCustomMessageHandler('hideLoading', function(message) {
    const overlay = document.getElementById(message.id);
    if (overlay) {
      overlay.style.display = 'none';
    }
  });

  // Update performance indicator
  Shiny.addCustomMessageHandler('updatePerformance', function(message) {
    const dot = document.querySelector('.indicator-dot');
    const text = document.querySelector('.indicator-text');

    if (!dot || !text) return;

    const timeMs = message.time_ms || 0;
    const cells = message.cells || 0;

    // Update text
    text.textContent = `${Math.round(timeMs)}ms · ${cells} cells`;

    // Update dot color based on performance
    dot.classList.remove('fast', 'medium', 'slow', 'very-slow');
    if (timeMs < 100) {
      dot.classList.add('fast');
    } else if (timeMs < 300) {
      dot.classList.add('medium');
    } else if (timeMs < 1000) {
      dot.classList.add('slow');
    } else {
      dot.classList.add('very-slow');
    }
  });

  // Toggle shortcuts overlay
  Shiny.addCustomMessageHandler('toggleShortcuts', function(message) {
    const overlay = document.getElementById('shortcuts-overlay');
    if (overlay) {
      overlay.classList.toggle('visible');
    }
  });

  // Programmatic button click
  Shiny.addCustomMessageHandler('clickButton', function(message) {
    const button = document.getElementById(message.id);
    if (button) {
      button.click();
    }
  });

  // Toggle fullscreen
  Shiny.addCustomMessageHandler('toggleFullscreen', function(message) {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(err => {
        console.log('Fullscreen not available:', err);
      });
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen();
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════
  // KEYBOARD SHORTCUTS
  // ═══════════════════════════════════════════════════════════════════════

  document.addEventListener('keydown', function(e) {
    // Ignore if typing in an input
    if (e.target.tagName === 'INPUT' ||
        e.target.tagName === 'TEXTAREA' ||
        e.target.tagName === 'SELECT') {
      return;
    }

    const key = e.key.toLowerCase();

    // Send keypress to Shiny
    if (['?', 'r', 'd', 'f', 'e'].includes(key)) {
      Shiny.setInputValue('keypress', key, {priority: 'event'});
      e.preventDefault();
    }

    // Escape closes shortcuts overlay
    if (e.key === 'Escape') {
      const overlay = document.getElementById('shortcuts-overlay');
      if (overlay && overlay.classList.contains('visible')) {
        overlay.classList.remove('visible');
        e.preventDefault();
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════
  // IDLE DETECTION (BREATHING ANIMATION)
  // ═══════════════════════════════════════════════════════════════════════

  let idleTimer = null;
  const IDLE_TIMEOUT = 30000; // 30 seconds

  function resetIdleTimer() {
    // Remove breathing animation
    const plotContainer = document.querySelector('.plot-container');
    if (plotContainer) {
      plotContainer.classList.remove('zen-breathing');
    }

    // Clear existing timer
    if (idleTimer) {
      clearTimeout(idleTimer);
    }

    // Set new timer
    idleTimer = setTimeout(function() {
      if (plotContainer) {
        plotContainer.classList.add('zen-breathing');
      }
    }, IDLE_TIMEOUT);
  }

  // Reset on user activity
  ['mousemove', 'mousedown', 'keydown', 'touchstart', 'scroll'].forEach(function(event) {
    document.addEventListener(event, resetIdleTimer, { passive: true });
  });

  // Initialize idle timer
  resetIdleTimer();

  // ═══════════════════════════════════════════════════════════════════════
  // CLICK OUTSIDE TO CLOSE SHORTCUTS
  // ═══════════════════════════════════════════════════════════════════════

  document.addEventListener('click', function(e) {
    const overlay = document.getElementById('shortcuts-overlay');
    const content = document.querySelector('.shortcuts-content');

    if (overlay && overlay.classList.contains('visible')) {
      // If clicked outside content, close overlay
      if (content && !content.contains(e.target)) {
        overlay.classList.remove('visible');
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════
  // SIDEBAR COLLAPSE ENHANCEMENT
  // ═══════════════════════════════════════════════════════════════════════

  // Watch for sidebar toggle and update plot size
  const observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
        // Trigger window resize to update plot dimensions
        setTimeout(function() {
          window.dispatchEvent(new Event('resize'));
        }, 350); // Wait for CSS transition
      }
    });
  });

  // Start observing sidebar when it exists
  document.addEventListener('DOMContentLoaded', function() {
    const sidebar = document.querySelector('.bslib-sidebar-layout > .sidebar');
    if (sidebar) {
      observer.observe(sidebar, { attributes: true });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════
  // EXPORT BUTTONS VISIBILITY
  // ═══════════════════════════════════════════════════════════════════════

  // Show export buttons on plot hover
  document.addEventListener('DOMContentLoaded', function() {
    const plotContainer = document.querySelector('.plot-container');
    const exportControls = document.querySelector('.export-controls');

    if (plotContainer && exportControls) {
      plotContainer.addEventListener('mouseenter', function() {
        exportControls.style.opacity = '1';
      });

      plotContainer.addEventListener('mouseleave', function() {
        exportControls.style.opacity = '0.7';
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════
  // CONSOLE LOG
  // ═══════════════════════════════════════════════════════════════════════

  console.log('%c🌀 Spiralizer Zen Mode', 'color: #00ff88; font-size: 14px; font-weight: bold;');
  console.log('%cPress ? for keyboard shortcuts', 'color: #888;');

})();
