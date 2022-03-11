import ArgumentParser
import Darwin.ncurses
import Foundation
import Parsing

// TODO: Edit todos.
// TODO: Look at the Windows.
// TODO: Improvements with window handling. Multiple lines. Scrolling.
// TODO: Watch for file changes.

struct Arguments: ParsableArguments {
    @Argument(help: "File with Markdown tasks format.")
    var file: String
}

let arguments = Arguments.parseOrExit()
let filePath = arguments.file
let file = try String(contentsOfFile: filePath)

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
    OneOf {
        todoLine.map(Row.task)
        Prefix { $0 != "\n" }.map(String.init).map(Row.unrecognized)
    }
} separator: {
    Newline()
} terminator: {
    End()
}

var input = file[...]
var state = State(data: try todosParser.parse(&input))

var currentTab = 0

setlocale(LC_CTYPE, "en_US.UTF-8")
initscr()
noecho()
curs_set(0) // Makes cursor invisble
keypad(stdscr, true)
use_default_colors()
// timeout(500)
defer { endwin() }

var lastInputChar = ""

let left = newwin(0, 0, 0, 0)!
let right = newwin(0, 0, 0, 0)!

var createMode = false {
    didSet {
        if createMode {
            echo()
        } else {
            noecho()
        }
    }
}

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
        for (i, taskIndex) in list.elements.enumerated() {
            if isCurrentTab, list.current == i {
                wattron(window, reversed)
            }
            let task = state.task(at: taskIndex)
            let text = "[\(task.completed ? "x" : " ")] \(task.text)"
            mvwaddstr(window, Int32(i) + 1, 1, text)
            wattroff(window, reversed)
        }
        if isCurrentTab {
            wattron(window, reversed)
        }
        let title = " \(list.name) "
        mvwaddstr(window, 0, (width / 2) / 2 - Int32(title.count / 2), title)
        wattroff(window, reversed)
    }
    drawList(state.todosList, window: left, isCurrentTab: currentTab == 0)
    drawList(state.donesList, window: right, isCurrentTab: currentTab == 1)

    // Bottom bar
    do {
        var bottomBar = "`q` to quit. `c` to create a new task."
        #if DEBUG
            bottomBar.append("\t\tc? \(createMode) w: \(width) h: \(height) - \(lastInputChar) \(KEY_ENTER)")
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
    if createMode {
        mvaddstr(height - 2, 0, "New task:")

        let cstring = UnsafeMutablePointer<CChar>
            .allocate(capacity: 1024)
        defer { cstring.deallocate() }

        getstr(cstring)

        let input = String(cString: cstring)

        state.addTask(input)
        try state.save(to: filePath)

        createMode = false
    } else {
        let input = getch()
        lastInputChar = "\(input)"
        switch input {
        case "q".ascii32: // quit
            quit = true
        case "c".ascii32: // create mode
            createMode = true
        case KEY_UP:
            if currentTab == 0 {
                state.todosList.up()
            } else {
                state.donesList.up()
            }
        case KEY_DOWN:
            if currentTab == 0 {
                state.todosList.down()
            } else {
                state.donesList.down()
            }
        case "\n".ascii32, " ".ascii32:
            if currentTab == 0 {
                state.markTaskAsDone()
            } else {
                state.markTaskAsTodo()
            }
            try state.save(to: filePath)
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
}

delwin(left)
delwin(right)

try state.save(to: filePath)
