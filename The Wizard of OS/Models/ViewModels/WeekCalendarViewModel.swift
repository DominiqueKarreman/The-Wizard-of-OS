////
////  WeekCalendarViewModel.swift
////  The Wizard of OS
////
////  Created by Dominique Karreman on 5/17/25.
////
//
//
//
//class WeekCalendarViewModel: ObservableObject {
//    @Published var events: [EKEvent] = []
//    private let eventStore = EKEventStore()
//    let hourHeight: CGFloat = 60
//    let daysInWeek = 7
//
//    init() {
//        requestAccess { granted in
//            if granted {
//                self.fetchEvents()
//            } else {
//                print("Calendar access denied")
//            }
//        }
//    }
//
//    func requestAccess(completion: @escaping (Bool) -> Void) {
//        eventStore.requestAccess(to: .event) { granted, error in
//            DispatchQueue.main.async {
//                completion(granted)
//            }
//        }
//    }
//
//    func fetchEvents() {
//        let calendar = Calendar.current
//        let today = Date()
//        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return }
//        let endOfWeek = calendar.date(byAdding: .day, value: daysInWeek, to: startOfWeek)!
//
//        let predicate = eventStore.predicateForEvents(withStart: startOfWeek, end: endOfWeek, calendars: nil)
//        let ekEvents = eventStore.events(matching: predicate).filter { !$0.isAllDay }
//        DispatchQueue.main.async {
//            self.events = ekEvents
//        }
//    }
//
//    func createEvent(title: String, start: Date, end: Date) {
//        let event = EKEvent(eventStore: eventStore)
//        event.title = title
//        event.startDate = start
//        event.endDate = end
//        event.calendar = eventStore.defaultCalendarForNewEvents
//        do {
//            try eventStore.save(event, span: .thisEvent)
//            fetchEvents()
//        } catch {
//            print("Error saving event: \(error)")
//        }
//    }
//
//    func updateEvent(_ event: EKEvent, newStart: Date, newEnd: Date) {
//        event.startDate = newStart
//        event.endDate = newEnd
//        do {
//            try eventStore.save(event, span: .thisEvent)
//            fetchEvents()
//        } catch {
//            print("Error updating event: \(error)")
//        }
//    }
//
//    func deleteEvent(_ event: EKEvent) {
//        do {
//            try eventStore.remove(event, span: .thisEvent)
//            fetchEvents()
//        } catch {
//            print("Error deleting event: \(error)")
//        }
//    }
//
//    func columnWidth(containerSize: CGSize) -> CGFloat {
//        let totalWidth = max(containerSize.width - 60, 700)
//        return totalWidth / CGFloat(daysInWeek)
//    }
//
//    func formattedDate(for index: Int) -> String {
//        let calendar = Calendar.current
//        let today = Date()
//        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
//        let adjustedStart = calendar.date(byAdding: .day, value: 1, to: startOfWeek)! // Monday start
//        let date = calendar.date(byAdding: .day, value: index, to: adjustedStart)!
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMM d"
//        return formatter.string(from: date)
//    }
//
//    func frameForEvent(_ event: EKEvent, in containerSize: CGSize, columnIndex: Int, overlapIndex: Int, overlapCount: Int) -> CGRect? {
//        guard !event.isAllDay else { return nil }
//
//        let columnW = columnWidth(containerSize: containerSize)
//        let startOfDay = Calendar.current.startOfDay(for: event.startDate)
//        let startInterval = event.startDate.timeIntervalSince(startOfDay)
//        let endInterval = event.endDate.timeIntervalSince(startOfDay)
//
//        let startY = 40 + CGFloat(startInterval / 3600) * hourHeight
//        let height = max(CGFloat((endInterval - startInterval) / 3600) * hourHeight, 30)
//
//        let xBase = 60 + CGFloat(columnIndex) * columnW
//        let eventWidth = columnW / CGFloat(overlapCount)
//
//        return CGRect(x: xBase + CGFloat(overlapIndex) * eventWidth,
//                      y: startY,
//                      width: eventWidth,
//                      height: height)
//    }
//
//    func groupEventsByDay(_ events: [EKEvent]) -> [Int: [EKEvent]] {
//        var grouped: [Int: [EKEvent]] = [:]
//        let calendar = Calendar.current
//        for event in events {
//            let weekday = calendar.component(.weekday, from: event.startDate)
//            let adjustedDay = (weekday + 5) % 7 // Monday = 0
//            grouped[adjustedDay, default: []].append(event)
//        }
//        return grouped
//    }
//
//    func splitIntoOverlapGroups(_ events: [EKEvent]) -> [[EKEvent]] {
//        var groups: [[EKEvent]] = []
//
//        for event in events.sorted(by: { $0.startDate < $1.startDate }) {
//            var added = false
//            for i in 0..<groups.count {
//                if !groups[i].contains(where: { isOverlapping($0, event) }) {
//                    groups[i].append(event)
//                    added = true
//                    break
//                }
//            }
//            if !added {
//                groups.append([event])
//            }
//        }
//        return groups
//    }
//
//    private func isOverlapping(_ e1: EKEvent, _ e2: EKEvent) -> Bool {
//        return e1.startDate < e2.endDate && e2.startDate < e1.endDate
//    }
//}
