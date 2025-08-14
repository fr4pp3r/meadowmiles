# MeadowMiles 🚗

**Your next adventure starts here. Rent your perfect ride today!**

MeadowMiles is a comprehensive Flutter-based vehicle rental platform that connects vehicle owners with renters, creating a seamless peer-to-peer car sharing marketplace.

## 🌟 Features

### For Renters
- **Browse Vehicles**: Explore available cars, motorcycles, vans, and SUVs
- **Smart Search**: Filter by location, price, vehicle type, and availability
- **Easy Booking**: Simple booking process with date selection and payment proof upload
- **Booking Management**: Track current and past rentals with real-time status updates
- **Rating System**: Rate and review rental experiences

### For Vehicle Owners (Rentees)
- **Vehicle Management**: Add, edit, and manage vehicle listings with photos
- **Pricing Control**: Set competitive daily rates and availability schedules
- **Booking Oversight**: Review and manage incoming rental requests
- **Revenue Tracking**: Monitor earnings with detailed financial reports
- **Performance Analytics**: Track vehicle utilization and customer feedback

### For Administrators
- **User Management**: Verify users and manage platform access
- **Data Analytics**: Comprehensive platform statistics and insights
- **Support Tools**: Handle customer inquiries and dispute resolution
- **System Administration**: Platform configuration and maintenance

## 🏗️ Technology Stack

- **Frontend**: Flutter (Dart) with Material Design 3
- **Backend**: Firebase (Authentication, Firestore) + Supabase
- **State Management**: Provider pattern
- **Platforms**: iOS, Android, Web, macOS, Windows, Linux
- **Authentication**: Firebase Auth with role-based access control
- **Database**: Cloud Firestore for real-time data synchronization

## 📱 App Architecture

### User Roles
- **Renter**: Users who rent vehicles
- **Rentee/Owner**: Vehicle owners who list their vehicles for rent
- **Admin**: Platform administrators with full system access

### Core Models
- **UserModel**: User profiles with role-based permissions and verification status
- **Vehicle**: Comprehensive vehicle information including specs, pricing, and availability
- **Booking**: Complete rental transaction lifecycle with status tracking and payment management

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.8.1)
- Firebase project setup
- Supabase project configuration

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd meadowmiles
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update `firebase_options.dart` with your project configuration

4. **Configure Supabase**
   - Update the Supabase URL and anon key in `main.dart`

5. **Run the application**
   ```bash
   flutter run
   ```

## 📂 Project Structure

```
lib/
├── components/          # Reusable UI components
├── models/             # Data models (User, Vehicle, Booking)
├── pages/              # Application screens
│   ├── admin/          # Admin dashboard and tools
│   ├── auth/           # Authentication screens
│   ├── booking/        # Booking management
│   ├── profile/        # User profile management
│   ├── rentee/         # Vehicle owner features
│   ├── renter/         # Renter features
│   └── vehicle/        # Vehicle management
├── states/             # State management (Provider)
├── main.dart           # Application entry point
└── theme.dart          # App theming and styling
```

## 🎨 Design System

- **Typography**: Custom Copperplate Gothic font family
- **Color Scheme**: Material Design 3 with custom primary/secondary colors
- **UI Components**: Consistent Material Design components with custom styling
- **Responsive Design**: Adaptive layouts for various screen sizes

## 🔧 Key Dependencies

- `firebase_core` & `firebase_auth`: Authentication and backend services
- `cloud_firestore`: Real-time database
- `supabase_flutter`: Additional backend capabilities
- `provider`: State management
- `image_picker`: Vehicle photo uploads
- `country_code_picker`: International phone number support
- `url_launcher`: External link handling
- `intl`: Internationalization and date formatting

## 🚦 Development Workflow

### Running Tests
```bash
flutter test
```

### Building for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 📋 Roadmap

- [ ] Real-time GPS tracking for vehicles
- [ ] In-app messaging between renters and owners
- [ ] Advanced payment gateway integration
- [ ] Multi-language support
- [ ] Push notifications for booking updates
- [ ] Vehicle insurance integration

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and inquiries, please contact the development team or create an issue in the repository.

---

**MeadowMiles** - Connecting journeys, one ride at a time. 🌱🚗
