#' @keywords internal
"_PACKAGE"

#' @importFrom htmltools HTML tagList tags htmlEscape renderTags renderDependencies
#' @importFrom htmltools copyDependencyToDir
#' @importFrom utils modifyList
NULL

# Named one by one rather than imported wholesale, so this block doubles as the inventory
# of what a real site actually needs from muiMaterial. Note what is absent: no
# `*.shinyInput()` anywhere. The pages are static HTML with no Shiny server behind them, so
# every stateful component is the `.triggerId` or `.static` form, which keeps its state
# inside React.

#' @importFrom muiMaterial muiMaterialPage ThemeProvider CssBaseline
#' @importFrom muiMaterial AppBar Toolbar Drawer.triggerId
#' @importFrom muiMaterial List ListItemButton ListItemText
#' @importFrom muiMaterial Box Container Grid Stack
#' @importFrom muiMaterial Typography Link Button IconButton
#' @importFrom muiMaterial Card CardActions CardContent CardMedia
#' @importFrom muiMaterial Accordion AccordionDetails AccordionSummary
#' @importFrom muiMaterial TabContext.static TabList.static Tab TabPanel
#' @importFrom muiMaterial Dialog.triggerId DialogContent
NULL
