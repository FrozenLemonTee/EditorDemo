///|
const APP_WIDTH : Int = 80

///|
const APP_HEIGHT : Int = 24

///|
const CURSOR_BLINK_POLLS : Int = 16

///|
struct DemoEditor {
  section : @base.Section
  mut lines : Array[Array[Char]]
  mut cursor_x : Int
  mut cursor_y : Int
  mut cursor_visible : Bool
}

///|
fn DemoEditor::new(
  left : Int,
  top : Int,
  width : Int,
  height : Int,
  text? : String = "",
) -> DemoEditor {
  DemoEditor::{
    section: @base.Section::new(
      @base.Area::new(@cmp.maximum(0, width), @cmp.maximum(0, height)),
      @cmp.maximum(0, left),
      @cmp.maximum(0, top),
    ),
    lines: DemoEditor::from_text(text),
    cursor_x: 0,
    cursor_y: 0,
    cursor_visible: true,
  }
}

///|
fn DemoEditor::from_text(text : String) -> Array[Array[Char]] {
  let lines : Array[Array[Char]] = []
  let mut line : Array[Char] = []
  for _, ch in text.iter2() {
    if ch == '\n' {
      lines.push(line)
      line = []
    } else if ch != '\r' {
      line.push(ch)
    }
  }
  lines.push(line)
  lines
}

///|
fn DemoEditor::width(self : DemoEditor) -> Int {
  self.section.area.width
}

///|
fn DemoEditor::height(self : DemoEditor) -> Int {
  self.section.area.height
}

///|
fn DemoEditor::set_cursor_visible(
  self : DemoEditor,
  visible : Bool,
) -> Bool {
  if self.cursor_visible == visible {
    return false
  }
  self.cursor_visible = visible
  true
}

///|
fn DemoEditor::toggle_cursor(self : DemoEditor) -> Unit {
  self.cursor_visible = !self.cursor_visible
}

///|
fn DemoEditor::current_line_length(self : DemoEditor) -> Int {
  if self.cursor_y < 0 || self.cursor_y >= self.lines.length() {
    return 0
  }
  self.lines[self.cursor_y].length()
}

///|
fn DemoEditor::normalize_cursor(self : DemoEditor) -> Unit {
  if self.lines.length() == 0 {
    self.lines.push([])
  }
  if self.cursor_y < 0 {
    self.cursor_y = 0
  }
  if self.cursor_y >= self.lines.length() {
    self.cursor_y = self.lines.length() - 1
  }
  let line_len = self.current_line_length()
  if self.cursor_x < 0 {
    self.cursor_x = 0
  }
  if self.cursor_x > line_len {
    self.cursor_x = line_len
  }
}

///|
fn DemoEditor::insert_char(self : DemoEditor, ch : Char) -> Unit {
  self.normalize_cursor()
  let current = self.lines[self.cursor_y]
  let insert_pos = @cmp.minimum(self.cursor_x, current.length())
  let new_line : Array[Char] = []
  for i, cur in current.iter2() {
    if i < insert_pos {
      new_line.push(cur)
    }
  }
  new_line.push(ch)
  for i, cur in current.iter2() {
    if i >= insert_pos {
      new_line.push(cur)
    }
  }
  self.lines[self.cursor_y] = new_line
  self.cursor_x = insert_pos + 1
}

///|
fn DemoEditor::insert_text(self : DemoEditor, text : String) -> Unit {
  for _, ch in text.iter2() {
    self.insert_char(ch)
  }
}

///|
fn DemoEditor::backspace(self : DemoEditor) -> Unit {
  self.normalize_cursor()
  if self.cursor_x > 0 {
    let current = self.lines[self.cursor_y]
    let remove_pos = self.cursor_x - 1
    let new_line : Array[Char] = []
    for i, cur in current.iter2() {
      if i != remove_pos {
        new_line.push(cur)
      }
    }
    self.lines[self.cursor_y] = new_line
    self.cursor_x = remove_pos
    return
  }
  if self.cursor_y == 0 {
    return
  }
  let prev_line = self.lines[self.cursor_y - 1]
  let current_line = self.lines[self.cursor_y]
  let merged : Array[Char] = []
  for _, ch in prev_line.iter2() {
    merged.push(ch)
  }
  for _, ch in current_line.iter2() {
    merged.push(ch)
  }
  let new_lines : Array[Array[Char]] = []
  for i, line in self.lines.iter2() {
    if i == self.cursor_y - 1 {
      new_lines.push(merged)
    } else if i != self.cursor_y {
      new_lines.push(line)
    }
  }
  self.lines = new_lines
  self.cursor_y -= 1
  self.cursor_x = prev_line.length()
}

///|
fn DemoEditor::newline(self : DemoEditor) -> Unit {
  self.normalize_cursor()
  let current = self.lines[self.cursor_y]
  let left_line : Array[Char] = []
  let right_line : Array[Char] = []
  let split_pos = @cmp.minimum(self.cursor_x, current.length())
  for i, ch in current.iter2() {
    if i < split_pos {
      left_line.push(ch)
    } else {
      right_line.push(ch)
    }
  }
  let new_lines : Array[Array[Char]] = []
  for i, line in self.lines.iter2() {
    if i == self.cursor_y {
      new_lines.push(left_line)
      new_lines.push(right_line)
    } else {
      new_lines.push(line)
    }
  }
  self.lines = new_lines
  self.cursor_y += 1
  self.cursor_x = 0
}

///|
fn DemoEditor::move_left(self : DemoEditor) -> Unit {
  self.normalize_cursor()
  if self.cursor_x > 0 {
    self.cursor_x -= 1
    return
  }
  if self.cursor_y > 0 {
    self.cursor_y -= 1
    self.cursor_x = self.current_line_length()
  }
}

///|
fn DemoEditor::move_right(self : DemoEditor) -> Unit {
  self.normalize_cursor()
  let line_len = self.current_line_length()
  if self.cursor_x < line_len {
    self.cursor_x += 1
    return
  }
  if self.cursor_y + 1 < self.lines.length() {
    self.cursor_y += 1
    self.cursor_x = 0
  }
}

///|
fn DemoEditor::move_up(self : DemoEditor) -> Unit {
  self.normalize_cursor()
  if self.cursor_y == 0 {
    return
  }
  self.cursor_y -= 1
  self.cursor_x = @cmp.minimum(self.cursor_x, self.current_line_length())
}

///|
fn DemoEditor::move_down(self : DemoEditor) -> Unit {
  self.normalize_cursor()
  if self.cursor_y + 1 >= self.lines.length() {
    return
  }
  self.cursor_y += 1
  self.cursor_x = @cmp.minimum(self.cursor_x, self.current_line_length())
}

///|
fn DemoEditor::handle_key(
  self : DemoEditor,
  key : @base.KeyEvent,
) -> @base.EventResult {
  if key.state == @base.KeyState::Up {
    return @base.EventResult::Ignored
  }
  match key.code {
    @base.KeyCode::Character =>
      match key.text {
        None => @base.EventResult::Ignored
        Some(text) =>
          if key.modifiers.ctrl || key.modifiers.alt || key.modifiers.meta {
            @base.EventResult::Handled
          } else {
            self.insert_text(text)
            self.normalize_cursor()
            @base.EventResult::Redraw
          }
      }
    @base.KeyCode::Space =>
      if key.modifiers.ctrl || key.modifiers.alt || key.modifiers.meta {
        @base.EventResult::Handled
      } else {
        self.insert_char(' ')
        self.normalize_cursor()
        @base.EventResult::Redraw
      }
    @base.KeyCode::Tab => {
      self.insert_text("  ")
      self.normalize_cursor()
      @base.EventResult::Redraw
    }
    @base.KeyCode::Enter => {
      self.newline()
      self.normalize_cursor()
      @base.EventResult::Redraw
    }
    @base.KeyCode::Backspace => {
      self.backspace()
      self.normalize_cursor()
      @base.EventResult::Redraw
    }
    @base.KeyCode::Left => {
      self.move_left()
      self.normalize_cursor()
      @base.EventResult::Redraw
    }
    @base.KeyCode::Right => {
      self.move_right()
      self.normalize_cursor()
      @base.EventResult::Redraw
    }
    @base.KeyCode::Up => {
      self.move_up()
      self.normalize_cursor()
      @base.EventResult::Redraw
    }
    @base.KeyCode::Down => {
      self.move_down()
      self.normalize_cursor()
      @base.EventResult::Redraw
    }
    _ => @base.EventResult::Handled
  }
}

///|
fn DemoEditor::render(self : DemoEditor, frame : @base.Frame) -> Unit {
  let subframe = frame.subframe(
    self.section.left,
    self.section.top,
    self.section.area.width,
    self.section.area.height,
  )
  let rows = @cmp.minimum(self.lines.length(), self.height())
  for row in 0..<rows {
    let line = self.lines[row]
    let cols = @cmp.minimum(line.length(), self.width())
    for col in 0..<cols {
      subframe.set_chars(col, row, line[col])
    }
  }
  if self.cursor_visible &&
    self.cursor_y < self.height() &&
    self.cursor_x < self.width() {
    subframe.set_chars(self.cursor_x, self.cursor_y, '_')
  }
}

///|
fn DemoEditor::handle_event(
  self : DemoEditor,
  event : @base.Event,
) -> @base.EventResult {
  match event.kind {
    @base.EventKind::Key =>
      match event.key {
        None => @base.EventResult::Ignored
        Some(key) => self.handle_key(key)
      }
    @base.EventKind::TextInput =>
      match event.text_input {
        None => @base.EventResult::Ignored
        Some(text_input) => {
          self.insert_text(text_input.text)
          self.normalize_cursor()
          @base.EventResult::Redraw
        }
      }
    _ => @base.EventResult::Ignored
  }
}

///|
struct DemoApp {
  mut running : Bool
  editor : DemoEditor
  mut status : String
  mut blink_polls : Int
}

///|
fn DemoApp::new() -> DemoApp {
  DemoApp::{
    running: true,
    editor: DemoEditor::new(
      2,
      6,
      APP_WIDTH - 4,
      APP_HEIGHT - 9,
      text="Type here. Arrow keys move the cursor. Backspace edits. q or Esc exits.",
    ),
    status: "Waiting for TerminalEvent input...",
    blink_polls: 0,
  }
}

///|
fn draw_text(frame : @base.Frame, left : Int, top : Int, text : String) -> Unit {
  for i, ch in text.iter2() {
    frame.set_chars(left + i, top, ch)
  }
}

///|
fn draw_box(
  frame : @base.Frame,
  left : Int,
  top : Int,
  width : Int,
  height : Int,
) -> Unit {
  if width <= 1 || height <= 1 {
    return
  }
  for x in 0..<width {
    frame.set_chars(left + x, top, '-')
    frame.set_chars(left + x, top + height - 1, '-')
  }
  for y in 0..<height {
    frame.set_chars(left, top + y, '|')
    frame.set_chars(left + width - 1, top + y, '|')
  }
  frame.set_chars(left, top, '+')
  frame.set_chars(left + width - 1, top, '+')
  frame.set_chars(left, top + height - 1, '+')
  frame.set_chars(left + width - 1, top + height - 1, '+')
}

///|
fn is_plain_q(key : @base.KeyEvent) -> Bool {
  match key.text {
    Some("q") =>
      !key.modifiers.shift &&
      !key.modifiers.ctrl &&
      !key.modifiers.alt &&
      !key.modifiers.meta
    _ => false
  }
}

///|
fn is_ctrl_s(key : @base.KeyEvent) -> Bool {
  match key.text {
    Some("s") => key.modifiers.ctrl
    _ => false
  }
}

///|
fn DemoApp::handle_key(
  self : DemoApp,
  key : @base.KeyEvent,
) -> @base.EventResult {
  if key.state == @base.KeyState::Up {
    return @base.EventResult::Ignored
  }
  self.blink_polls = 0
  ignore(self.editor.set_cursor_visible(true))
  if key.code == @base.KeyCode::Esc || is_plain_q(key) {
    self.running = false
    self.status = "Exit requested. Restoring terminal..."
    return @base.EventResult::Redraw
  }
  if is_ctrl_s(key) {
    self.status = "Ctrl+S observed by demo shell. File I/O is intentionally out of MVP scope."
    return @base.EventResult::Redraw
  }
  self.status = "Last event: key"
  self.editor.handle_event(@base.Event::key(key))
}

///|
fn DemoApp::tick_cursor(self : DemoApp) -> @base.EventResult {
  self.blink_polls += 1
  if self.blink_polls < CURSOR_BLINK_POLLS {
    return @base.EventResult::Ignored
  }
  self.blink_polls = 0
  self.editor.toggle_cursor()
  @base.EventResult::Redraw
}

///|
pub impl @base.Widget for DemoApp with fn width(self : DemoApp) -> Int {
  ignore(self)
  APP_WIDTH
}

///|
pub impl @base.Widget for DemoApp with fn height(self : DemoApp) -> Int {
  ignore(self)
  APP_HEIGHT
}

///|
pub impl @base.Widget for DemoApp with fn render(
  self : DemoApp,
  frame : @base.Frame,
) -> Unit {
  draw_box(frame, 0, 0, APP_WIDTH, APP_HEIGHT)
  draw_text(frame, 2, 0, " TerminalEvent + LunarTUI MVP Demo ")
  draw_text(
    frame, 2, 2, "Input path: C++ backend -> MoonBit binding -> LunarTUI adapter -> Widget",
  )
  draw_text(
    frame, 2, 3, "Keys: type text, arrows move cursor, Backspace edits, Ctrl+S marks status",
  )
  draw_text(frame, 2, 4, "Quit: q or Esc")
  draw_box(frame, 1, 5, APP_WIDTH - 2, APP_HEIGHT - 7)
  self.editor.render(frame)
  draw_text(frame, 2, APP_HEIGHT - 2, self.status)
}

///|
pub impl @base.Widget for DemoApp with fn handle_event(
  self : DemoApp,
  event : @base.Event,
) -> @base.EventResult {
  match event.kind {
    @base.EventKind::Key =>
      match event.key {
        Some(key) => self.handle_key(key)
        None => @base.EventResult::Ignored
      }
    @base.EventKind::TextInput => {
      self.status = "Last event: text input"
      self.editor.handle_event(event)
    }
    @base.EventKind::Resize => {
      self.status = "Last event: resize"
      @base.EventResult::Redraw
    }
    @base.EventKind::Focus => {
      self.status = "Last event: focus"
      @base.EventResult::Redraw
    }
    @base.EventKind::Mouse => {
      self.status = "Last event: mouse"
      @base.EventResult::Handled
    }
  }
}

///|
fn run_demo(source : @lte_lunartui.EventSource) -> Unit {
  let app = DemoApp::new()
  let terminal = @terminal.Terminal::new(@base.Area::new(APP_WIDTH, APP_HEIGHT))
  @terminal.Terminal::clear()
  @terminal.Terminal::hide_cursor()
  terminal.draw(app)
  while app.running {
    match source.poll_event(32) {
      Some(event) =>
        match app.handle_event(event) {
          @base.EventResult::Redraw => terminal.draw(app)
          @base.EventResult::Handled => ()
          @base.EventResult::Ignored => ()
        }
      None =>
        match app.tick_cursor() {
          @base.EventResult::Redraw => terminal.draw(app)
          @base.EventResult::Handled => ()
          @base.EventResult::Ignored => ()
        }
    }
  }
  @terminal.Terminal::show_cursor()
  @terminal.Terminal::flush()
  source.restore_terminal()
  source.shutdown()
  @terminal.Terminal::clear()
  @terminal.Terminal::move_cursor(0, 0)
  println("TerminalEvent demo exited.")
}

///|
fn main {
  let source = @lte_lunartui.EventSource::new()
  match source.enter_raw_mode() {
    Ok(_) => run_demo(source)
    Err(_) => {
      source.shutdown()
      println("TerminalEvent raw mode is unavailable in this environment.")
      println(
        "The MVP backend is POSIX-oriented; run this demo in a POSIX terminal to exercise the interactive loop.",
      )
    }
  }
}
