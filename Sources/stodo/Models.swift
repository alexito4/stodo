struct Todo {
    var completed: Bool
    var text: String
}

struct List {
    var name: String
    var current: Int?
    var elements: [Todo]
    
    mutating func clamp() {
        guard !elements.isEmpty else {
            current = nil
            return
        }
        if current != nil {
            current = max(min(current!, elements.count - 1), 0)
        } else {
            current = 0
        }
    }
    
    mutating func up() {
        guard !elements.isEmpty else {
            current = nil
            return
        }
        if current != nil {
            current! -= 1
            clamp()
        } else {
            current = 0
        }
    }
    
    mutating func down() {
        guard !elements.isEmpty else {
            current = nil
            return
        }
        if current != nil {
            current! += 1
            clamp()
        } else {
            current = 0
        }
    }
    
    mutating func select() -> Todo? {
        guard !elements.isEmpty else {
            return nil
        }
        guard let current = current else {
            return nil
        }

        elements[current].completed.toggle()
        
        defer { clamp() }
        return elements.remove(at: current)
    }
    
    mutating func add(_ todo: Todo) {
        elements.append(todo)
        if current == nil {
            current = 0
        }
    }
}

extension Array where Element == List {
    
    func save(to filePath: String) throws {
        let tasks = self.flatMap { list in
            list.elements.map { task in
                "- [\(task.completed ? "x" : " ")] \(task.text)"
            }
        }
        let contents = tasks.joined(separator: "\n")
        try contents.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
}
