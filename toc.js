// Populate the sidebar
//
// This is a script, and not included directly in the page, to control the total size of the book.
// The TOC contains an entry for each page, so if each page includes a copy of the TOC,
// the total size of the page becomes O(n**2).
class MDBookSidebarScrollbox extends HTMLElement {
    constructor() {
        super();
    }
    connectedCallback() {
        this.innerHTML = '<ol class="chapter"><li class="chapter-item expanded affix "><li class="part-title">Regelgeving</li><li class="chapter-item expanded "><a href="title_i.html"><strong aria-hidden="true">1.</strong> Titel I: Broclette, zijn stichting en zijn frequentie</a></li><li class="chapter-item expanded "><a href="title_ii.html"><strong aria-hidden="true">2.</strong> Titel II: Het regelement van Broclette</a></li><li><ol class="section"><li class="chapter-item expanded "><a href="title_ii_ch_i.html"><strong aria-hidden="true">2.1.</strong> Hoofdstuk I: De Geboden</a></li><li class="chapter-item expanded "><a href="title_ii_ch_ii.html"><strong aria-hidden="true">2.2.</strong> Hoofdstuk II: De Regels</a></li><li class="chapter-item expanded "><a href="title_ii_ch_iii.html"><strong aria-hidden="true">2.3.</strong> Hoofdstuk III: Strafmaat</a></li></ol></li><li class="chapter-item expanded "><a href="title_iii.html"><strong aria-hidden="true">3.</strong> Titel III: De Brocletters en hun rechten</a></li><li class="chapter-item expanded "><a href="title_iv.html"><strong aria-hidden="true">4.</strong> Titel IV: Tagsatzung</a></li><li><ol class="section"><li class="chapter-item expanded "><a href="title_iv_ch_i.html"><strong aria-hidden="true">4.1.</strong> Hoofdstuk I: Agenda</a></li><li class="chapter-item expanded "><a href="title_iv_ch_ii.html"><strong aria-hidden="true">4.2.</strong> Hoofdstuk II: Stemmingen</a></li></ol></li><li class="chapter-item expanded "><a href="title_v.html"><strong aria-hidden="true">5.</strong> Titel V: Raclette maaltijd</a></li><li class="chapter-item expanded "><a href="title_vi.html"><strong aria-hidden="true">6.</strong> Titel VI: Toetreding</a></li><li class="chapter-item expanded affix "><li class="spacer"></li><li class="chapter-item expanded affix "><li class="part-title">Status Quo</li><li class="chapter-item expanded "><a href="statistics.html"><strong aria-hidden="true">7.</strong> Statistieken</a></li><li class="chapter-item expanded "><a href="cognomen.html"><strong aria-hidden="true">8.</strong> Cognomen</a></li></ol>';
        // Set the current, active page, and reveal it if it's hidden
        let current_page = document.location.href.toString().split("#")[0].split("?")[0];
        if (current_page.endsWith("/")) {
            current_page += "index.html";
        }
        var links = Array.prototype.slice.call(this.querySelectorAll("a"));
        var l = links.length;
        for (var i = 0; i < l; ++i) {
            var link = links[i];
            var href = link.getAttribute("href");
            if (href && !href.startsWith("#") && !/^(?:[a-z+]+:)?\/\//.test(href)) {
                link.href = path_to_root + href;
            }
            // The "index" page is supposed to alias the first chapter in the book.
            if (link.href === current_page || (i === 0 && path_to_root === "" && current_page.endsWith("/index.html"))) {
                link.classList.add("active");
                var parent = link.parentElement;
                if (parent && parent.classList.contains("chapter-item")) {
                    parent.classList.add("expanded");
                }
                while (parent) {
                    if (parent.tagName === "LI" && parent.previousElementSibling) {
                        if (parent.previousElementSibling.classList.contains("chapter-item")) {
                            parent.previousElementSibling.classList.add("expanded");
                        }
                    }
                    parent = parent.parentElement;
                }
            }
        }
        // Track and set sidebar scroll position
        this.addEventListener('click', function(e) {
            if (e.target.tagName === 'A') {
                sessionStorage.setItem('sidebar-scroll', this.scrollTop);
            }
        }, { passive: true });
        var sidebarScrollTop = sessionStorage.getItem('sidebar-scroll');
        sessionStorage.removeItem('sidebar-scroll');
        if (sidebarScrollTop) {
            // preserve sidebar scroll position when navigating via links within sidebar
            this.scrollTop = sidebarScrollTop;
        } else {
            // scroll sidebar to current active section when navigating via "next/previous chapter" buttons
            var activeSection = document.querySelector('#sidebar .active');
            if (activeSection) {
                activeSection.scrollIntoView({ block: 'center' });
            }
        }
        // Toggle buttons
        var sidebarAnchorToggles = document.querySelectorAll('#sidebar a.toggle');
        function toggleSection(ev) {
            ev.currentTarget.parentElement.classList.toggle('expanded');
        }
        Array.from(sidebarAnchorToggles).forEach(function (el) {
            el.addEventListener('click', toggleSection);
        });
    }
}
window.customElements.define("mdbook-sidebar-scrollbox", MDBookSidebarScrollbox);
