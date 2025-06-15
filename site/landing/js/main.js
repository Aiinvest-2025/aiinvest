document.addEventListener("DOMContentLoaded", function () {
    let loaded = false;
    const swapSection = document.getElementById('swap');
    const swapIframeContainer = document.getElementById('swap-iframe-container');

    if ('IntersectionObserver' in window && swapSection) {
        const observer = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (entry.isIntersecting && !loaded) {
                    loaded = true;
                    swapIframeContainer.innerHTML = `
                        <iframe
                            src="https://app.uniswap.org/swap?outputCurrency=0xcF2dF5724e66666601a18f1553CD4c77FECb344f&chain=mainnet"
                            height="660" width="420" style="max-width: 480px; border: none; border-radius: 16px;"></iframe>
                    `;
                    observer.disconnect();
                }
            });
        }, { threshold: 0.2 });
        observer.observe(swapSection);
    }
});