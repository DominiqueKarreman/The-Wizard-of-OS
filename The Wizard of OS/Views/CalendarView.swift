import SwiftUI
import EventKit
#if os(macOS)
import AppKit
#endif

struct CalendarEvent: Codable, Identifiable {
    var id = UUID()
    var title: String
    var startDate: Date
    var endDate: Date
}
struct WeekCalendarView: View {

    @State var gwnietsupdated: String
    @StateObject private var calendarManager = CalendarManager()
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedEventID: String? = nil
    @State private var selectedEventForEditing: EKEvent? = nil
    @State private var selectedGrid: (day: Int, hour: Int)? = nil
    @State private var currentTime = Date()
    
//    @State private var isOptimizing: Bool = false
    
    @State private var draggingEvent: EKEvent?
    @GestureState private var dragOffset: CGSize = .zero

    let days: [String] = {
        var symbols = Calendar.current.shortWeekdaySymbols
        let sunday = symbols.removeFirst()
        symbols.append(sunday)
        return symbols
    }()
    let hours = Array(0..<24)
    let hourHeight: CGFloat = 60

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if calendarManager.showQuestionOverlay {
                    ZStack {
                        VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)

                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    calendarManager.showQuestionOverlay = false
                                    calendarManager.questionText = nil
                                    calendarManager.questionAnswer = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 24))
                                        .padding()
                                }
                            }
                            .padding(.top, 30)

                            Spacer()

                            if calendarManager.isLoadingQuestionResponse {
                                GlowingOrb().padding()
                                TypingText(fullText: "Performing your magic spell...")
                            } else {
                                VStack(spacing: 12) {
                                    Text("Ask a question about your schedule:")
                                        .font(.title3)
                                        .foregroundColor(.white)

                                    TextField("e.g. When is my next free evening?",
                                              text: Binding(
                                                get: { calendarManager.questionText ?? "" },
                                                set: { calendarManager.questionText = $0 }
                                              )
                                    )
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 400)

                                    Button("Submit") {
                                        if let question = calendarManager.questionText, !question.isEmpty {
                                            calendarManager.askScheduleQuestion()
                                        }
                                    }
                                    .buttonStyle(DefaultButtonStyle())

                                    if let answer = calendarManager.questionAnswer {
                                        Text(answer)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .padding(.top, 16)
                                            .frame(maxWidth: 500)
                                    }
                                }
                                .padding()
                            }

                            Spacer()
                        }
                        .padding(30)
                    }
                    .frame(maxWidth: 1355, maxHeight: 1000)
                    .offset(x: -10)
                    .transition(.opacity)
                    .zIndex(101)
                }
                if calendarManager.showSummaryOverlay {
                    ZStack {
                        VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
//                                            .edgesIgnoringSafeArea(.all)

                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    calendarManager.showSummaryOverlay = false
                                    calendarManager.planningSummary = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 24))
                                        .padding()
                                }
                            }
                            .padding(.top, 30)

                            Spacer()

                            if calendarManager.isLoadingSummary || calendarManager.isOptimizing {
                                GlowingOrb().padding()
                                TypingText(fullText: calendarManager.isLoadingSummary ? "Analyzing your week..." : "Summoning your plan...")
                            } else if let summary = calendarManager.planningSummary {
                                ScrollView(.vertical) {
                                    Text(summary)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                }.frame(maxHeight: 1200)
                            }
                            
                            Spacer()
                        }.padding(30)
                    }.frame(maxWidth: 1355, maxHeight: 1000).offset(x:-10, y:0)
                    .transition(.opacity)
                    .zIndex(101)
                }
                Image("MagicPattern")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width + 50, height: geometry.size.height + 250)
                    .clipped()
                    .overlay(
                        Color.black.opacity(colorScheme == .dark ? 0.5 : 0.0)
                    )
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // --- Begin new header style ---
                    VStack(spacing: 0) {
                        ZStack {
                            Color.black.opacity(0.6)
                            HStack {
                                Button(action: {
                                    calendarManager.goToPreviousWeek()
                                }) {
                                    Image(systemName: "chevron.left")
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.leading)

                                Spacer()

                                Text(monthAndYear(for: calendarManager.currentWeekStart))
                                    .font(.title3)
                                    .bold()

                                Spacer()

                                Button(action: {
                                    calendarManager.goToNextWeek()
                                }) {
                                    Image(systemName: "chevron.right")
                                }
                                .buttonStyle(PlainButtonStyle())
//                                .padding(.trailing)
                            }
                            .frame(width: 200, height: 40)
                            .foregroundColor(.white)
                        }

                        // --- Inserted: Additional row with buttons and search field ---
                        ZStack {
                            Color.black.opacity(0.6)
                            GeometryReader { geometry in
                                HStack {
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            let calendar = Calendar.current
                                            // Get the Monday of the current week for today (Dutch week start)
                                            let today = Date()
                                            if let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
                                               let monday = calendar.date(byAdding: .day, value: 1, to: startOfWeek) {
                                                calendarManager.currentWeekStart = monday
                                                calendarManager.fetchEvents()
                                            }
                                        }) {
                                            Image(systemName: "calendar.badge.checkmark")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 25, height: 25)  // Adjust as needed
                                        }
                                        .help("Jumps calendar to today")
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        
                                        Button(action: {
                                            if calendarManager.showQuestionOverlay {
                                                calendarManager.showQuestionOverlay = false
                                                calendarManager.questionResponse = nil
                                            } else {
                                                calendarManager.showQuestionOverlay = true
                                                calendarManager.isLoadingQuestionResponse = false
                                                calendarManager.questionResponse = ""
                                            }
                                        }) {
                                            Image(systemName: "questionmark.circle")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 25, height: 25)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .help("Ask a question about your schedule")
                                        
                                        Button(action: {
                                            calendarManager.isLoadingSummary = true
                                            calendarManager.showSummaryOverlay = true
                                            calendarManager.fetchPlanningSummary { summary in
                                                DispatchQueue.main.async {
                                                    if let summary = summary {
                                                        calendarManager.planningSummary = summary
                                                    } else {
                                                        calendarManager.planningSummary = "⚠️ Failed to fetch planning summary."
                                                    }
                                                    calendarManager.isLoadingSummary = false
                                                }
                                            }
                                        }) {
                                            Image(systemName: "brain")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 25, height: 25)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: {
                                            calendarManager.isOptimizing = true
                                            calendarManager.showSummaryOverlay = true
                                            calendarManager.planningSummary = nil

                                            calendarManager.sendEventsToOptimizeEndpoint()
                                        }) {
                                            Image(systemName: "sparkles")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 25, height: 25)  // Adjust as needed
                                        } .buttonStyle(PlainButtonStyle())
                                        
                                    }

                                    Spacer()

                                    TextField("Search", text: .constant(""))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: min(200, geometry.size.width * 0.3)).offset(x: -50)
                                }
                                .padding(.horizontal, 16)
                                .frame(width: geometry.size.width * 1 , height: 40)
                                
                            }
                        }
                        // --- End inserted row ---

                        ZStack {
                            Color.black.opacity(0.6)
                            HStack(spacing: 0) {
                                Color.clear.frame(width: 60)

                                ForEach(0..<7) { index in
                                    VStack(spacing: 2) {
                                        Text(days[index])
                                            .font(.headline)
                                            .foregroundColor(.white)

                                        Text(formattedDate(for: index))
                                            .font(.caption)
                                            .foregroundColor(.white)

                                        if Calendar.current.isDate(
                                            Calendar.current.date(byAdding: .day, value: index, to: calendarManager.currentWeekStart)!,
                                            inSameDayAs: currentTime
                                        ) {
                                            Rectangle()
                                                .fill(Color.red)
                                                .frame(height: 2)
                                                .padding(.top, 2)
                                        } else {
                                            Color.clear.frame(height: 2).padding(.top, 2)
                                        }
                                    }
                                    .frame(width: columnWidth(containerSize: geometry.size), height: 40)
                                }
                            }.offset(x: -25)
                        }
                    }
                    .frame(height: 120)
                    .zIndex(2)
                    .ignoresSafeArea(.container, edges: .top)
                    // --- End new header style ---

                    ScrollView(.vertical) {
                        VStack {
                            ZStack(alignment: .topLeading) {
                                Color.clear
                                    .contentShape(Rectangle())
                                    .gesture(
                                        TapGesture(count: 2)
                                            .onEnded { _ in
                                                let location = NSEvent.mouseLocation
                                                if let window = NSApp.keyWindow,
                                                   let contentView = window.contentView {
                                                    // Convert mouse location to local coordinates within the scroll view
                                                    let localPoint = contentView.convert(location, from: nil)
                                                    let localFrame = geometry.frame(in: .global)

                                                    // Adjust Y position based on the scroll view's position
                                                    let yInView = localPoint.y - localFrame.minY - 60  // 60 is for the header height
                                                    
                                                    // Calculate the hour based on the vertical position
                                                    let hour = max(0, min(23, Int(yInView / hourHeight)))

                                                    // Calculate the correct day by dividing X position by column width
                                                    let dayWidth = columnWidth(containerSize: geometry.size)
                                                    let dayIndex = min(max(Int((localPoint.x - 60) / dayWidth), 0), 6)

                                                    // Calculate the start date based on the clicked day and hour
                                                let calendar = Calendar.current
                                                let startOfWeek = calendarManager.currentWeekStart
                                                if let baseDate = calendar.date(byAdding: .day, value: dayIndex, to: startOfWeek) {
                                                    let startDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: baseDate)!
                                                    let endDate = startDate.addingTimeInterval(3600) // Default 1-hour event
                                                    calendarManager.createEvent(title: "New Event", start: startDate, end: endDate)
                                                    calendarManager.fetchEvents()
                                                }
                                                }
                                            }
                                    )
                                    .onTapGesture {
                                        selectedEventID = nil
                                    }

                                VStack(spacing: 0) {
                                    ForEach(0..<24) { hour in
                                        HStack(spacing: 0) {
                                            Text("\(hour):00")
                                                .frame(width: 60, height: hourHeight, alignment: .topTrailing)
                                                .padding(.trailing, 4)

                                            ForEach(0..<7, id: \.self) { dayIndex in
                                                let columnW = columnWidth(containerSize: geometry.size)
                                                ZStack {
                                                    Rectangle()
                                                        .fill(Color.blue.opacity(0.00001))
                                                        .frame(width: columnW, height: hourHeight)
                                                        .border(Color.gray.opacity(0.1), width: 1)
                                                }
                                                .onTapGesture(count: 2) {
                                                    selectedGrid = (dayIndex, hour)
                                                    print(selectedGrid)
                                                    
                                                    let calendar = Calendar.current
                                                    let startOfWeek = calendarManager.currentWeekStart
                                                    if let baseDate = calendar.date(byAdding: .day, value: dayIndex, to: startOfWeek) {
                                                        let startDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: baseDate)!
                                                        let endDate = startDate.addingTimeInterval(3600) // Default 1-hour event
                                                        calendarManager.createEvent(title: "New Event", start: startDate, end: endDate)
                                                        calendarManager.fetchEvents()
                                                        selectedGrid = nil
                                                    }
                                                        
                                                        
                                                    print(selectedGrid)
                                                }
                                            }
                                        }
                                    }
                                }

                                let groupedEvents = groupEventsByDay(calendarManager.events)

                                ForEach(0..<7, id: \.self) { dayIndex in
                                    let eventsForDay = groupedEvents[dayIndex] ?? []
                                    let overlapGroups = splitIntoOverlapGroups(eventsForDay)

                                    ForEach(overlapGroups.indices, id: \.self) { groupIndex in
                                        let group = overlapGroups[groupIndex]
                                        ForEach(group.indices, id: \.self) { eventIndex in
                                            let event = group[eventIndex]
                                            if let frame = frameForEvent(event, in: geometry.size, columnIndex: dayIndex, overlapIndex: eventIndex, overlapCount: group.count) {
                                                let isEditable = event.calendar.allowsContentModifications

                                                EventView(
                                                    event: event,
                                                    frame: frame,
                                                    isEditable: isEditable,
                                                    isActive: draggingEvent?.eventIdentifier == event.eventIdentifier || selectedEventID == event.eventIdentifier,
                                                    onResizeTop: { delta in
                                                        let minutes = round((delta / hourHeight) * 60 / 15) * 15
                                                        let newStart = event.startDate.addingTimeInterval(TimeInterval(minutes * 60))
                                                        calendarManager.updateEvent(event, newStart: newStart, newEnd: event.endDate)
                                                    },
                                                    onResizeBottom: { delta in
                                                        let minutes = round((delta / hourHeight) * 60 / 15) * 15
                                                        let newEnd = event.endDate.addingTimeInterval(TimeInterval(minutes * 60))
                                                        calendarManager.updateEvent(event, newStart: event.startDate, newEnd: newEnd)
                                                    },
                                                    onDelete: {
                                                            calendarManager.deleteEvent(event)
                                                            if selectedEventID == event.eventIdentifier {
                                                                selectedEventID = nil
                                                            }
                                                        }
                                                )
                                                .offset(y: draggingEvent?.eventIdentifier == event.eventIdentifier ? dragOffset.height : 0)
                                                .gesture(
                                                    isEditable ? DragGesture()
                                                        .updating($dragOffset) { value, state, _ in
                                                            let totalMinutes = round((value.translation.height / hourHeight) * 60 / 15) * 15
                                                            state = CGSize(width: 0, height: CGFloat(totalMinutes / 60) * hourHeight)
                                                        }
                                                        .onChanged { _ in
                                                            draggingEvent = event
                                                        }
                                                        .onEnded { value in
                                                            let totalMinutes = round((value.translation.height / hourHeight) * 60 / 15) * 15
                                                            let secondsDragged = TimeInterval(totalMinutes * 60)
                                                            let newStart = event.startDate.addingTimeInterval(secondsDragged)
                                                            let newEnd = event.endDate.addingTimeInterval(secondsDragged)
                                                            calendarManager.updateEvent(event, newStart: newStart, newEnd: newEnd)
                                                            draggingEvent = nil
                                                        }
                                                    : nil
                                                )
                                                .onTapGesture {
                                                    if NSEvent.modifierFlags.contains(.option) {
                                                        selectedEventForEditing = event
                                                    } else {
                                                        selectedEventID = event.eventIdentifier
                                                    }
                                                }
                                                .zIndex(draggingEvent?.eventIdentifier == event.eventIdentifier ? 1 : 0)
                                            }
                                        }
                                    }
                                }
                              
                                
                                // After your existing grid and event views, add this red line overlay:

                                GeometryReader { geo in
                                    if Calendar.current.isDate(currentTime, equalTo: calendarManager.currentWeekStart, toGranularity: .weekOfYear) {
                                        let calendar = Calendar.current
                                        let startOfDay = calendar.startOfDay(for: currentTime)
                                        let secondsSinceStart = currentTime.timeIntervalSince(startOfDay)
                                        let yOffset = 0 + CGFloat(secondsSinceStart / 3600.0) * hourHeight

                                        Path { path in
                                            let startX: CGFloat = 60
                                            let endX = geo.size.width
                                            path.move(to: CGPoint(x: startX, y: yOffset))
                                            path.addLine(to: CGPoint(x: endX, y: yOffset))
                                        }
                                        .stroke(Color.red, lineWidth: 2)
                                        .zIndex(1)
                                        .allowsHitTesting(false)
                                    }
                                }
                            }
                            .frame(height: hourHeight * 24 + 300)
                        }
                    }
                    .padding(.top, -30)
                }
                .zIndex(0)
                .onAppear {
                    calendarManager.requestAccess { granted in
                        if granted {
                            calendarManager.fetchEvents()
                        } else {
                            print("Access denied to calendar")
                        }
                    }
                }
                KeyboardCatcher {
                    if let selectedID = selectedEventID,
                       let event = calendarManager.events.first(where: { $0.eventIdentifier == selectedID }),
                       event.calendar.allowsContentModifications {
                        calendarManager.deleteEvent(event)
                        selectedEventID = nil
                    }
                }
                .frame(width: 0, height: 0)
                
               
                
                
                
                // Sidebar for editing event
                if let event = selectedEventForEditing {
                    GeometryReader { geometry in
                        HStack(alignment: .top, spacing: 0) {
                            EditEventView(event: Binding(get: {
                                selectedEventForEditing!
                            }, set: {
                                selectedEventForEditing = $0
                            }), calendarManager: calendarManager) {
                                selectedEventForEditing = nil
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
            }
        }
    }

    func columnWidth(containerSize: CGSize) -> CGFloat {
        let totalWidth = max(containerSize.width - 60, 700)
        return totalWidth / 7
    }

    func formattedDate(for index: Int) -> String {
        let calendar = Calendar.current
        let startOfWeek = calendarManager.currentWeekStart
        let date = calendar.date(byAdding: .day, value: index, to: startOfWeek)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    func frameForEvent(_ event: EKEvent, in containerSize: CGSize, columnIndex: Int, overlapIndex: Int, overlapCount: Int) -> CGRect? {
        guard !event.isAllDay else { return nil }

        let columnW = columnWidth(containerSize: containerSize)
        let startOfDay = Calendar.current.startOfDay(for: event.startDate)
        let startInterval = event.startDate.timeIntervalSince(startOfDay)
        let endInterval = event.endDate.timeIntervalSince(startOfDay)

        let startY = 40 + CGFloat(startInterval / 3600) * hourHeight
        let height = max(CGFloat((endInterval - startInterval) / 3600) * hourHeight, 30)

        let xBase = 60 + CGFloat(columnIndex) * columnW
        let eventWidth = columnW / CGFloat(overlapCount)
        let x = xBase + CGFloat(overlapIndex) * eventWidth

        return CGRect(x: x, y: startY, width: eventWidth, height: height)
    }

    func groupEventsByDay(_ events: [EKEvent]) -> [Int: [EKEvent]] {
        var dict = [Int: [EKEvent]]()
        for event in events {
            if event.isAllDay { continue }
            guard let weekday = Calendar.current.dateComponents([.weekday], from: event.startDate).weekday else { continue }
            let dayIndex = (weekday + 5) % 7 == 6 ? 6 : (weekday + 5) % 7
            dict[dayIndex, default: []].append(event)
        }
        return dict
    }

    func splitIntoOverlapGroups(_ events: [EKEvent]) -> [[EKEvent]] {
        let sorted = events.sorted { $0.startDate < $1.startDate }
        var groups: [[EKEvent]] = []

        for event in sorted {
            var placed = false
            for i in 0..<groups.count {
                if !groups[i].contains(where: { !isOverlapping($0, event) }) {
                    groups[i].append(event)
                    placed = true
                    break
                }
            }
            if !placed {
                groups.append([event])
            }
        }
        return groups
    }

    func isOverlapping(_ a: EKEvent, _ b: EKEvent) -> Bool {
        return a.startDate < b.endDate && b.startDate < a.endDate
    }
}



#Preview {
    WeekCalendarView()
}

    func monthAndYear(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

#if os(macOS)
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
#endif
