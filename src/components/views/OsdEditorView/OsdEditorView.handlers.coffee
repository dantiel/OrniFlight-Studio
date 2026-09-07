###
# Pointer-interaction and layout helpers for OsdEditorView. Kept out of
# the CHAML (fieldHandlers pattern) so the markup stays terse and the
# geometry stays unit-testable without a DOM.
###
import {
  GRID_COLS, GRID_ROWS, cellFromPointer, findFreeCell, posCell
} from '../../../lib/osdCatalog.coffee'

osdItemStyle = (draft, index) ->
  cell = posCell draft[index]
  {
    left: "#{cell.x * 100 / GRID_COLS}%"
    top: "#{cell.y * 100 / GRID_ROWS}%"
    width: "#{100 / GRID_COLS}%"
    height: "#{100 / GRID_ROWS}%"
  }

makeOsdHandlers = (osd, gridRef, setSelected) ->
  cellAt = (event) ->
    rect = gridRef.current?.getBoundingClientRect()
    return null unless rect?
    cellFromPointer event.clientX, event.clientY, rect

  beginDragAt = (event, item) ->
    event.preventDefault()
    # jsdom has no setPointerCapture; the ?. guard keeps tests green.
    event.currentTarget.setPointerCapture? event.pointerId
    osd.beginDrag item.index
    setSelected item.index

  dragAt = (event) ->
    return unless osd.dragState?
    cell = cellAt event
    osd.dragTo cell.x, cell.y if cell?

  endDragAt = (event) ->
    return unless osd.dragState?
    cell = cellAt event
    if cell? then osd.dropAt cell.x, cell.y else osd.cancelDrag()

  cancelDrag = ->
    osd.cancelDrag()

  addItem = (item) ->
    osd.placeItem(
      item.index, (findFreeCell(osd.draft) or { x: 14, y: 7 })
    )
    setSelected item.index

  # Bound closures keep the CHAML attribute lines short.
  {
    beginDragAt, dragAt, endDragAt, cancelDrag, addItem
    addFor: (item) -> (-> addItem item)
    pointerDownFor: (item) -> (event) -> beginDragAt event, item
  }

export default makeOsdHandlers
export { makeOsdHandlers, osdItemStyle }