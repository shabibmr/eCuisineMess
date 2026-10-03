/* token-slip.js - Unified renderer for token slip print, preview modal and thermal feed animation */

window.Mess = window.Mess || {};

(function(Mess) {
  function padRight(str, len) {
    str = String(str || '');
    while (str.length < len) str += ' ';
    return str.slice(0, len);
  }

  function padLeft(str, len) {
    str = String(str || '');
    while (str.length < len) str = ' ' + str;
    return str.slice(-len);
  }

  Mess.renderTokenSlipHtml = function(bill, options) {
    options = options || {};
    var isDuplicate = options.isDuplicate || options.showDuplicate || (bill && bill.is_duplicate) || false;
    var width = options.width || '80mm';
    var companyName = options.companyName || 'DIT MESS FACILITY';

    var tokenNum = bill.token_number || (bill.meal_code + '-0001');
    var mealName = bill.meal_name || (bill.meal_code === 'B' ? 'BREAKFAST' : bill.meal_code === 'L' ? 'LUNCH' : 'DINNER');
    
    // Format Date and Time
    var dateStr = bill.date || (Mess.format ? Mess.format.date(new Date()) : new Date().toISOString().slice(0, 10));
    var timeStr = bill.time || (Mess.format ? Mess.format.time(new Date()) : '12:00');

    var customerName = bill.customer_name || 'Walk-in Member';
    var customerCode = bill.customer_code ? `(${bill.customer_code})` : '';
    var cuisineName = bill.cuisine_name || 'Standard';
    var counterId = bill.counter_id || 'C1';
    var userName = bill.user_name || bill.created_by || 'staff';

    var items = bill.items || [];
    var charWidth = width === '58mm' ? 32 : 40;
    var divider = '-'.repeat(charWidth);

    var itemsHtml = '';
    if (items.length === 0) {
      itemsHtml = '<div style="font-style:italic; padding:4px 0;">Standard Thali / Buffet</div>';
    } else {
      var itemLines = items.map(function(item) {
        var name = item.item_name || item.name || 'Item';
        var qty = String(item.quantity || item.qty || 1);
        var nameColWidth = charWidth - 5;
        return `${padRight(name, nameColWidth)}${padLeft(qty, 4)}`;
      });
      itemsHtml = `<pre style="margin:0; font-family:inherit; font-size:inherit; text-align:left; white-space:pre;">${itemLines.join('\n')}</pre>`;
    }

    return `
      <div class="token-slip ${width === '58mm' ? 'width-58mm' : ''}" style="box-sizing:border-box; font-family:'Courier New', Courier, monospace; text-align:center; background:#ffffff; color:#000000; padding:12px; margin:0 auto; line-height:1.35; font-size:12px;">
        <div class="slip-header-title font-bold" style="font-size:14px; letter-spacing:1px; margin-bottom:2px;">${companyName}</div>
        <div class="slip-header-sub" style="font-size:12px; letter-spacing:0.5px;">MESS TOKEN</div>

        ${isDuplicate ? `
          <div class="slip-duplicate-watermark" style="margin:8px 0; border:2px dashed #000; padding:4px; font-weight:bold; font-size:14px; text-transform:uppercase; letter-spacing:1px;">
            *** DUPLICATE ***
          </div>
        ` : ''}

        <div style="font-family:inherit; margin:4px 0; overflow:hidden;">${divider}</div>

        <div style="display:flex; justify-content:space-between; font-weight:bold; font-size:16px; margin:4px 0;">
          <span>Token : ${tokenNum}</span>
          <span>${mealName.toUpperCase()}</span>
        </div>

        <div style="text-align:left; font-family:inherit; font-size:11px;">
          <div>Date  : ${dateStr}   ${timeStr}</div>
          <div>Name  : ${customerName} ${customerCode}</div>
          <div>Cuisine: ${cuisineName}</div>
        </div>

        <div style="font-family:inherit; margin:4px 0; overflow:hidden;">${divider}</div>

        <div style="display:flex; justify-content:space-between; font-weight:bold; font-size:11px; margin-bottom:4px;">
          <span>Item</span>
          <span>Qty</span>
        </div>

        ${itemsHtml}

        <div style="font-family:inherit; margin:4px 0; overflow:hidden;">${divider}</div>

        <div style="display:flex; justify-content:space-between; font-size:11px; color:#333333;">
          <span>Counter: ${counterId}</span>
          <span>User: ${userName}</span>
        </div>
      </div>
    `;
  };

  Mess.renderTokenSlip = function(bill, options) {
    var wrapper = document.createElement('div');
    wrapper.innerHTML = Mess.renderTokenSlipHtml(bill, options).trim();
    return wrapper.firstElementChild;
  };

  Mess.printTokenSlip = function(bill, options) {
    options = options || {};
    var html = Mess.renderTokenSlipHtml(bill, options);
    if (Mess.print && Mess.print.printHtml) {
      Mess.print.printHtml(html, 'css/print/token.css');
    } else {
      window.print();
    }
  };

  Mess.showTokenPreviewDialog = function(bill, options) {
    options = options || {};
    var currentWidth = options.width || '80mm';
    var isDup = options.isDuplicate || false;

    var container = document.createElement('div');
    container.className = 'token-preview-modal-body flex-col gap-md align-center';

    var controlsHtml = `
      <div class="flex-row justify-between align-center" style="width: 100%; border-bottom: 1px solid var(--separator); padding-bottom: 8px;">
        <div class="segmented-control width-toggle" role="radiogroup" aria-label="Paper width">
          <button type="button" class="${currentWidth === '80mm' ? 'active' : ''}" data-w="80mm">80 mm</button>
          <button type="button" class="${currentWidth === '58mm' ? 'active' : ''}" data-w="58mm">58 mm</button>
        </div>
        <button type="button" class="btn btn--primary btn-print-now">
          <i data-lucide="printer"></i> Print Token
        </button>
      </div>
      <div class="slip-render-target card-inset" style="padding: 16px; background: #555555; border-radius: var(--radius-sm); overflow: auto; max-height: 480px; width: 100%; display: flex; justify-content: center;">
      </div>
    `;

    container.innerHTML = controlsHtml;
    var target = container.querySelector('.slip-render-target');
    var printNowBtn = container.querySelector('.btn-print-now');
    var widthButtons = container.querySelectorAll('.width-toggle button');

    function refreshSlip() {
      target.innerHTML = Mess.renderTokenSlipHtml(bill, { width: currentWidth, isDuplicate: isDup });
    }

    widthButtons.forEach(function(btn) {
      btn.addEventListener('click', function() {
        widthButtons.forEach(function(b) { b.classList.remove('active'); });
        btn.classList.add('active');
        currentWidth = btn.getAttribute('data-w');
        refreshSlip();
      });
    });

    printNowBtn.addEventListener('click', function() {
      Mess.printTokenSlip(bill, { width: currentWidth, isDuplicate: isDup });
    });

    refreshSlip();

    if (Mess.dialog && Mess.dialog.alert) {
      Mess.dialog.alert({
        title: isDup ? 'Reprint Token (DUPLICATE)' : 'Mess Token Preview',
        content: container
      });
    }
  };

  Mess.animateTokenFeed = function(targetContainerEl, bill, options, onDone) {
    options = options || {};
    var html = Mess.renderTokenSlipHtml(bill, options);

    var slotWrapper = document.createElement('div');
    slotWrapper.className = 'thermal-feed-slot';
    slotWrapper.style.position = 'relative';
    slotWrapper.style.overflow = 'hidden';
    slotWrapper.style.width = options.width === '58mm' ? '220px' : '300px';
    slotWrapper.style.margin = '0 auto';
    slotWrapper.style.paddingTop = '8px';

    var slipEl = document.createElement('div');
    slipEl.innerHTML = html.trim();
    var innerSlip = slipEl.firstElementChild;
    innerSlip.style.transform = 'translateY(-100%)';
    innerSlip.style.transition = 'transform 600ms cubic-bezier(0.16, 1, 0.3, 1)';
    innerSlip.style.boxShadow = '0 6px 16px rgba(0,0,0,0.15)';

    slotWrapper.appendChild(innerSlip);
    targetContainerEl.innerHTML = '';
    targetContainerEl.appendChild(slotWrapper);

    // Audio cue
    if (Mess.audio && Mess.audio.ok) {
      Mess.audio.ok();
    }

    // Trigger sliding animation
    requestAnimationFrame(function() {
      requestAnimationFrame(function() {
        innerSlip.style.transform = 'translateY(0)';
      });
    });

    setTimeout(function() {
      if (typeof onDone === 'function') onDone(innerSlip);
    }, 650);
  };
})(window.Mess);
