import Foundation
import Darwin.ncurses
import ArgumentParser
import Parsing

// TODO: Insert new todo
// TODO: look at the windows???
// TODO: edit todos?


struct Arguments: ParsableArguments {
    @Argument(help: "File with Markdown tasks format.")
    var file: String
}

let arguments = Arguments.parseOrExit()
let filePath = arguments.file
let file = try String(contentsOfFile: filePath)
print(file)

let todoLine = Parse(Todo.init(completed:text:)) {
    "- ["
    OneOf {
        " ".map { false }
        "x".map { true }
    }
    "] "
    Prefix { $0 != "\n" }.map(String.init)
}
let todosParser = Many {
    todoLine
} separator: {
    Newline()
} terminator: {
    End()
}

var input = file[...]
let result = try todosParser.parse(&input)
var todos = List(name: "TODO", current: 0, elements: result.filter { !$0.completed })
var dones = List(name: "DONE", current: 0, elements: result.filter { $0.completed })

var currentTab = 0

setlocale(LC_CTYPE, "en_US.UTF-8")
initscr()
noecho()
curs_set(0) // Makes cursor invisble
keypad(stdscr, true)
use_default_colors()
//timeout(500)
defer { endwin() }



var lastInputChar = ""

let left = newwin(0, 0, 0, 0)!
let right = newwin(0, 0, 0, 0)!

var quit = false
while !quit {
    refresh()
    defer {
//        erase()
    }
    
    // Read the environment
    let width = COLS
    let height = LINES
    
    // Render
    werase(left)
    wresize(left, height - 1, width / 2)
    mvwin(right, 0, 0)
    box(left, 0, 0)
    
    werase(right)
    wresize(right, height - 1, width / 2)
    mvwin(right, 0, width / 2)
    box(right, 0, 0)

    
    func drawList(
        _ list: List,
        window: OpaquePointer,
        isCurrentTab: Bool
    ) {
        for (i, task) in list.elements.enumerated() {
            if isCurrentTab && list.current == i {
                wattron(window, reversed)
            }
            let text = "[\(task.completed ? "x" : " ")] \(task.text)"
            mvwaddstr(window, Int32(i) + 1, 1, text)
            wattroff(window, reversed)
        }
        if isCurrentTab {
            wattron(window, reversed)
        }
        let title = " \(list.name) "
        mvwaddstr(window, 0, (width / 2) / 2 - Int32(title.count/2), title)
        wattroff(window, reversed)
    }
    drawList(todos, window: left, isCurrentTab: currentTab == 0)
    drawList(dones, window: right, isCurrentTab: currentTab == 1)
        
    // Bottom bar
    do {
        var bottomBar = "`q` to quit."
        #if DEBUG
        bottomBar.append("\t\tw: \(width) h: \(height) - \(lastInputChar) \(KEY_ENTER)")
        #endif
        attron(reversed)
        let y = height - 1
        mvaddstr(y, 0, String(repeating: " ", count: Int(width)))
        mvaddstr(y, 0, bottomBar)
        attroff(reversed)
    }
    
    refresh()
    wrefresh(left)
    wrefresh(right)
    
    // Handle input
    let input = getch()
    lastInputChar = "\(input)"
    switch input {
    case "q".ascii32: // quit
        quit = true
    case KEY_UP:
        if currentTab == 0 {
            todos.up()
        } else {
            dones.up()
        }
    case KEY_DOWN:
        if currentTab == 0 {
            todos.down()
        } else {
            dones.down()
        }
    case "\n".ascii32, " ".ascii32:
        if currentTab == 0 {
            if let todo = todos.select() {
                dones.add(todo)
            }
        } else {
            if let todo = dones.select() {
                todos.add(todo)
            }
        }
        try [todos, dones].save(to: filePath)
    case "\t".ascii32:
        if currentTab == 0 {
            currentTab = 1
        } else {
            currentTab = 0
        }
    default:
        break
    }
}

delwin(left)
delwin(right)

try [todos, dones].save(to: filePath)
