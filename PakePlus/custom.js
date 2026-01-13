
// very important, if you don't know what it is, don't touch it
// 非常重要，不懂代码不要动，这里可以解决80%的问题，也可以生产1000+的bug
const hookClick = (e) => {
    const origin = e.target.closest('a')
    const isBaseTargetBlank = document.querySelector(
        'head base[target="_blank"]'
    )
    console.log('origin', origin, isBaseTargetBlank)
    if (
        (origin && origin.href && origin.target === '_blank') ||
        (origin && origin.href && isBaseTargetBlank)
    ) {
        e.preventDefault()
        console.log('handle origin', origin)
        location.href = origin.href
    } else {
        console.log('not handle origin', origin)
    }
}

window.open = function (url, target, features) {
    console.log('open', url, target, features)
    location.href = url
}


document.addEventListener('click', hookClick, { capture: true })

    // Auto-Coupon Activation Logic
    // Intercepts login requests and triggers offer links
    (function () {
        const originalFetch = window.fetch;
        const originalXHR = window.XMLHttpRequest.prototype.open;
        let couponsTriggered = false;

        // List of offer links to activate
        const couponLinks = [
            'https://swiggy.onelink.me/888564224/n8t8rxdy?fbclid=IwYWRpZAGrG5o21DOmAR4IEYrf4Skt9fvr1Ve625j5yPH8OxVSdepzkPPdsfDBe4krNtRRPeZurb9LXg_wapm_vBtIGIAVTDCft3_ryv-0Dg',
            'https://swiggy.onelink.me/888564224/zp7b090r',
            'https://swiggy.onelink.me/888564224/2mejixk6'
        ];

        window.triggerCoupons = function () {
            console.log("[PakePlus] Manual coupon trigger initiated.");
            couponLinks.forEach(link => {
                fetch(link, { mode: 'no-cors' })
                    .then(() => console.log("[PakePlus] Triggered coupon: " + link))
                    .catch(e => console.error("[PakePlus] Failed to trigger coupon: " + link, e));
            });
            alert("Offers Claimed! (Background process started)");
        };

        function triggerCoupons() {
            if (couponsTriggered) return;
            couponsTriggered = true;
            console.log("[PakePlus] Login detected/suspected. Activating coupons...");
            window.triggerCoupons(); // Call the global function
        }

        // Intercept fetch
        window.fetch = async function (...args) {
            const response = await originalFetch.apply(this, args);
            try {
                const url = (args[0] instanceof Request) ? args[0].url : args[0];
                // Detect login verification endpoints
                // verify-otp, login, authenticate are common keywords
                // We use 'verify' which is standard for OTP flows
                if (url && (typeof url === 'string') && (url.includes('verify') || url.includes('login') || url.includes('authenticate'))) {
                    if (response.ok) {
                        triggerCoupons();
                    }
                }
            } catch (e) {
                console.error("[PakePlus] Error in fetch interceptor", e);
            }
            return response;
        };

        // Intercept XHR (older apps might use this)
        window.XMLHttpRequest.prototype.open = function (method, url) {
            this.addEventListener('load', function () {
                try {
                    if ((url.includes('verify') || url.includes('login') || url.includes('authenticate')) && this.status >= 200 && this.status < 300) {
                        triggerCoupons();
                    }
                } catch (e) {
                    console.error("[PakePlus] Error in XHR interceptor", e);
                }
            });
            originalXHR.apply(this, arguments);
        };

    })();

// Remove "Get Swiggy App" Banner Logic
(function () {
    // 1. CSS Hiding for known attributes
    const style = document.createElement('style');
    style.innerHTML = `
            [aria-label*="Get Swiggy App"],
            [title*="Get Swiggy App"],
            .install-app-banner,
            .smart-banner { display: none !important; }
        `;
    document.head.appendChild(style);

    // 2. JS Mutation Hiding for dynamic elements
    function removeBanners() {
        // Text patterns to look for in fixed overlays
        const keywords = ["Get Swiggy App", "Open in App", "Use the App"];

        document.querySelectorAll('div, span, a, button').forEach(el => {
            if (!el.innerText) return;

            // Only target fixed/sticky elements (overlays)
            const style = window.getComputedStyle(el);
            if (style.position === 'fixed' || style.position === 'sticky') {
                // Check if it contains keywords
                if (keywords.some(k => el.innerText.includes(k) && el.innerText.length < 100)) {
                    // Double check it's not the main nav
                    if (!el.classList.contains('nav') && !el.classList.contains('header')) {
                        el.style.display = 'none';
                        el.style.visibility = 'hidden';
                        console.log("[PakePlus] Hidden banner:", el);
                    }
                }
            }
        });
    }

    // Run periodically to catch react re-renders
    setInterval(removeBanners, 1500);
})();
