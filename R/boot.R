# The one script this site writes of its own, and everything it does.
#
# It is a plain <script> at the end of <body> rather than an element in the React tree,
# because React does not execute a <script> it renders - a tag tree is data, and the browser
# never parses it as markup. So anything of ours that has to *run* lives here, and waits for
# React rather than being mounted by it.
#
# Two jobs, both of which need the page to exist first:
#
#   1. Take the prerendered fallback back out, once React has drawn the real page over it.
#      See R/fallback.R for why the fallback is there at all.
#   2. Light up the app bar tab of whatever band the reader is in.
#
# Both are opt-in and both degrade to nothing: with no JavaScript the fallback simply stays
# and is the page, and with no IntersectionObserver the tabs are what they were before.

# "React has mounted" is read as "the container holds an element that is not the <script>
# tag it was served with" - counting children would be wrong the moment shiny.react replaced
# them rather than appending to them.
BOOT_WAIT <- paste0(
  "var c=document.querySelector('.react-container');",
  "if(!c)return;",
  "var up=function(){",
  "for(var i=0;i<c.children.length;i++){",
  "if(c.children[i].tagName!=='SCRIPT')return true}",
  "return false};",
  "var fire=function(){for(var i=0;i<jobs.length;i++)jobs[i]();};",
  "if(up()){fire();return;}",
  "var o=new MutationObserver(function(){",
  "if(up()){o.disconnect();fire();}});",
  "o.observe(c,{childList:true,subtree:true});"
)

# The fallback is removed rather than hidden: leaving a second copy of every heading in the
# document would have the page claim two of each to anything reading it after mount.
BOOT_FALLBACK <- paste0(
  "jobs.push(function(){",
  "var f=document.getElementById('site-fallback');",
  "if(f)f.remove();});"
)

# Which band the reader is in, marked on its tab. An IntersectionObserver rather than a
# scroll listener - no work on the frames where nothing crossed - with a root margin that
# puts the decision line just under the sticky bar, so a band becomes current as its heading
# clears the chrome rather than as its last pixel enters the viewport.
#
# `seen` is keyed by band id and the topmost intersecting band wins, so the two that overlap
# while one scrolls past the other do not both light up.
BOOT_SPY <- paste0(
  "jobs.push(function(){",
  "var tabs=document.querySelectorAll('.nav-tab[data-nav]');",
  "if(!tabs.length||!window.IntersectionObserver)return;",
  "var seen={},order=[];",
  "var paint=function(){",
  "var cur=null,i;",
  "for(i=0;i<order.length;i++){if(seen[order[i]]){cur=order[i];break;}}",
  "for(i=0;i<tabs.length;i++){",
  "tabs[i].classList.toggle(",
  "'is-current',tabs[i].getAttribute('data-nav')===cur);}",
  "};",
  "var io=new IntersectionObserver(function(es){",
  "for(var i=0;i<es.length;i++)seen[es[i].target.id]=es[i].isIntersecting;",
  "paint();},{rootMargin:'-80px 0px -70% 0px'});",
  "for(var i=0;i<tabs.length;i++){",
  "var el=document.getElementById(tabs[i].getAttribute('data-nav'));",
  "if(el){order.push(el.id);io.observe(el);}}",
  "});"
)

#' The page's boot script
#'
#' Written at the end of `<body>`, outside the React tree. See the notes at the top of
#' `R/boot.R` for why it cannot be a component.
#'
#' @param home Whether this page carries the bands the scroll spy watches.
#' @inheritParams mui_theme
#' @return A `<script>` element, as a string, or `""` when it would have nothing to do.
#' @family render
#' @keywords internal
mui_boot_script <- function(home = FALSE, config = mui_config()) {
  jobs <- c(
    if (isTRUE(config$prerender %||% TRUE)) BOOT_FALLBACK,
    if (home) BOOT_SPY
  )
  if (!length(jobs)) {
    return("")
  }
  paste0(
    "<script>(function(){var jobs=[];",
    paste0(jobs, collapse = ""),
    BOOT_WAIT,
    "})();</script>"
  )
}
