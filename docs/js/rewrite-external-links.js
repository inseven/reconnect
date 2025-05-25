function observe(callback) {
    const observer = new MutationObserver(function(mutations, observer) {
        mutations.forEach(function(mutation) {
            for (let i = 0; i < mutation.addedNodes.length; i++) {
                callback(mutation.addedNodes[i]);
            }
        });
    });
    observer.observe(document.body, {
        attributes: true,
        childList: true,
        subtree: true
    });
    callback(document.body);
}

observe((root) => {
    var elements = document.evaluate("//a", root, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
    for (let i = 0, length = elements.snapshotLength; i < length; ++i) {
        var element = elements.snapshotItem(i);
        if (element.hasAttribute("href") &&
            element.getAttribute("href").startsWith("http") &&
            !element.classList.contains("no-rewrite") &&
            element.target != "_blank") {
            element.target="_blank";
        }
    }
});
