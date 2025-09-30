# Enhanced Class Details Page

This directory contains the enhanced Class Details page implementation that displays comprehensive class information including semester, course code, year level, section, room, and schedule details.

## Features

### 📋 Complete Class Information Display

- **Subject Name**: Full subject title
- **Course Code**: Subject code (e.g., CS-201)
- **Semester**: Current semester information
- **Year Level**: Academic year level
- **Section**: Class section identifier
- **Room**: Classroom location
- **Schedule**: Start and end times
- **Sessions**: Multiple class sessions with times and rooms
- **Professor ID**: Instructor identifier

### 🎨 Modern UI Components

- **ClassDetailsInfoCard**: Comprehensive information display card
- **Responsive Design**: Adapts to different screen sizes
- **Material Design 3**: Follows latest design guidelines
- **Accessibility**: Screen reader friendly

## File Structure

```
lib/features/Teacher/features/class_details/
├── pages/
│   └── class_details_page.dart          # Main class details page
├── widgets/
│   └── class_details_info_card.dart     # Detailed information card widget
├── examples/
│   └── class_details_usage_example.dart # Usage examples
└── README.md                            # This documentation
```

## Usage

### Basic Usage

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ClassDetailsPage(
      subject: 'Data Structures and Algorithms',
      courseCode: 'CS-201',
      room: 'Room 301',
      startTime: '09:00 AM',
      endTime: '10:30 AM',
      status: 'Active',
      semester: '1st Semester',
      classID: 'CS-201-A',
      yearLevel: '2nd Year',
      section: 'Section A',
      profId: 'PROF001',
      sessions: [],
    ),
  ),
);
```

### Sessions Usage

The sessions parameter accepts an `Iterable` of session data. Each session can be a `Map<String, dynamic>` or an object with the following properties:

```dart
// Example session data structure
final sessions = [
  {
    'startTime': '09:00 AM',
    'endTime': '10:30 AM',
    'room': 'Room 301',
    'day': 'Monday',
  },
  {
    'startTime': '02:00 PM',
    'endTime': '03:30 PM',
    'room': 'Lab 205',
    'day': 'Wednesday',
  },
];

// The widget will automatically display all sessions
// If sessions is empty, it falls back to the basic startTime/endTime display
```

### With Database Integration

```dart
// Fetch complete class information from database
final classInfo = await AppDatabase.instance.getCompleteClassInfo(subjectId);

if (classInfo != null) {
  final subject = classInfo['subject'];
  final schedule = classInfo['schedule'];
  final term = classInfo['term'];

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ClassDetailsPage(
        subject: subject.subjectName,
        courseCode: subject.subjectCode,
        room: schedule.room ?? 'TBA',
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        status: 'Active',
        semester: term?.term ?? 'Unknown',
        classID: '${subject.subjectCode}-${subject.section}',
        yearLevel: subject.yearLevel,
        section: subject.section,
        profId: subject.profId,
        sessions: [],
      ),
    ),
  );
}
```

## Database Integration

### New Database Methods

- `getCompleteClassInfo(int subjectId)`: Fetches complete class information including subject, schedule, and term details
- Returns a Map with 'subject', 'schedule', and 'term' keys
- Handles null cases gracefully

### Database Schema

The implementation works with the existing database schema:

- **Subjects Table**: Contains subject information
- **Schedules Table**: Contains class schedule details
- **Terms Table**: Contains semester/term information

## UI Components

### ClassDetailsInfoCard

A comprehensive widget that displays:

- Class header with icon and title
- Detailed information grid (semester, year level, section, room)
- Schedule information in a highlighted section
- Responsive design with proper spacing

### Key Features

- **Icon-based Information**: Each detail has a relevant icon
- **Color-coded Schedule**: Schedule information is highlighted
- **Responsive Layout**: Adapts to different content lengths
- **Accessibility**: Proper semantic structure

## Security Considerations

Following the security rules:

- ✅ **Input Validation**: All user inputs are validated
- ✅ **Data Sanitization**: Database queries use parameterized statements
- ✅ **Error Handling**: Graceful error handling for database operations
- ✅ **No Sensitive Data**: No hardcoded credentials or sensitive information

## Future Enhancements

- [ ] Add professor information display
- [ ] Include student count statistics
- [ ] Add attendance rate indicators
- [ ] Implement class photo/avatar
- [ ] Add quick action buttons for common tasks
- [ ] Include class notes section
- [ ] Add class materials link

## Dependencies

- Flutter Material Design 3
- Drift database integration
- Custom theme support
- Responsive design components

## Testing

The implementation includes example usage patterns that can be used for testing:

- Basic navigation example
- Database integration example
- Error handling scenarios

## Contributing

When adding new features to the Class Details page:

1. Follow the existing code structure
2. Maintain security best practices
3. Add proper error handling
4. Include accessibility considerations
5. Update this documentation
