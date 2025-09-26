# Owner Application Feature Documentation

## Overview
This document describes the newly implemented Owner Application feature that allows renters to apply to become vehicle owners by uploading necessary documents including ORCR (Official Receipt & Certificate of Registration).

## Features Implemented

### 1. Owner Application Model (`owner_application_model.dart`)
- **OwnerApplication**: Main model for storing application data
- **VehicleDocument**: Model for storing uploaded document information
- **ApplicationStatus**: Enum for tracking application states (pending, underReview, approved, rejected)
- **DocumentType**: Enum for different document types (ORCR, driver's license, valid ID, etc.)

### 2. Owner Application Service (`owner_application_service.dart`)
- Document upload to Supabase storage
- Application submission and management
- Status checking and updates
- Admin functionality for approving/rejecting applications

### 3. Apply for Owner Page (`apply_for_owner_page.dart`)
- Multi-step form for owner application
- Document upload functionality with image picker
- Required and optional document sections
- Form validation and submission
- Real-time feedback and error handling

### 4. Application Status Page (`application_status_page.dart`)
- View current application status
- Display application details and uploaded documents
- Admin responses and feedback
- Action buttons based on status

### 5. Admin Review Page (`admin_owner_applications_page.dart`)
- Admin interface for reviewing applications
- Approve/reject functionality with custom responses
- Document viewing capabilities
- Application status management

## User Flow

### For Renters Applying to Become Owners:

1. **Navigate to Profile**: User goes to their profile page
2. **Click "Apply for Owner"**: Button appears for renters only
3. **Fill Application Form**: Complete business information and emergency contacts
4. **Upload Documents**: Upload required documents:
   - ORCR (Official Receipt & Certificate of Registration) - **Required**
   - Driver's License - **Required**
   - Valid Government ID - **Required**
   - Proof of Income - Optional
   - Other supporting documents - Optional
5. **Submit Application**: Review and submit with terms agreement
6. **Track Status**: Monitor application progress in status page

### For Admins Reviewing Applications:

1. **Access Admin Panel**: Navigate to owner applications section
2. **Review Applications**: View submitted applications with all details
3. **Examine Documents**: Check uploaded documents for authenticity
4. **Make Decision**: Approve or reject with custom feedback
5. **Notify Applicant**: System automatically updates applicant's status

## Technical Implementation

### Database Structure

#### Firestore Collection: `owner_applications`
```json
{
  "id": "OWN25012617301234",
  "userId": "user_id",
  "userName": "John Doe",
  "userEmail": "john@email.com",
  "phoneNumber": "+63912345678",
  "status": "pending",
  "documents": [
    {
      "id": "doc_1234567890",
      "type": "orcr",
      "fileName": "user_orcr_1234567890.jpg",
      "fileUrl": "https://supabase.url/storage/...",
      "uploadedAt": "2025-01-26T17:30:12.000Z",
      "description": "ORCR document"
    }
  ],
  "businessName": "John's Car Rental",
  "businessAddress": "123 Main St, City",
  "emergencyContactName": "Jane Doe",
  "emergencyContactPhone": "+63923456789",
  "reasonForApplication": "I want to rent out my car...",
  "createdAt": "2025-01-26T17:30:12.000Z",
  "updatedAt": "2025-01-26T18:00:12.000Z",
  "adminResponse": "Application approved",
  "adminId": "admin_user_id",
  "reviewedAt": "2025-01-26T18:00:12.000Z"
}
```

#### Supabase Storage Bucket: `owner-documents`
- Stores uploaded document files
- Organized by user ID and document type
- Secure access with signed URLs for viewing

### Routes Added
- `/apply_for_owner` - Owner application form
- `/application_status` - View application status
- `/admin_owner_applications` - Admin review page (to be added to admin dashboard)

### Services Integration
- **Firebase Firestore**: Stores application data
- **Supabase Storage**: Handles document file uploads
- **Image Picker**: Allows users to select/capture documents
- **Provider**: State management for user authentication

## Security Considerations

1. **Document Storage**: Files stored in private Supabase bucket with access controls
2. **User Authentication**: Only authenticated renters can apply
3. **Admin Authorization**: Only admin users can approve/reject applications
4. **Data Validation**: Comprehensive form validation on client and server side
5. **File Type Restrictions**: Only image files accepted for documents

## User Experience Features

1. **Progressive Disclosure**: Step-by-step application process
2. **Real-time Validation**: Immediate feedback on form inputs
3. **Visual Status Indicators**: Clear status displays with colors and icons
4. **Responsive Design**: Works on all device sizes
5. **Error Handling**: Graceful error messages and recovery options
6. **Document Preview**: Users can preview uploaded documents
7. **Progress Tracking**: Clear indication of application progress

## Installation and Setup

1. **Supabase Setup**: Create `owner-documents` storage bucket
2. **Firestore Rules**: Update security rules for `owner_applications` collection
3. **Dependencies**: Ensure all required packages are installed
4. **Route Registration**: Add new routes to main app router

### Firestore Security Rules Example:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /owner_applications/{applicationId} {
      // Users can create and read their own applications
      allow create: if request.auth != null && request.auth.uid == resource.data.userId;
      allow read: if request.auth != null && (
        request.auth.uid == resource.data.userId || 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin'
      );
      // Only admins can update applications
      allow update: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }
  }
}
```

### Supabase Storage Policy Example:
```sql
-- Allow authenticated users to upload to their own folder
CREATE POLICY "Users can upload own documents" ON storage.objects
FOR INSERT WITH CHECK (
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to read their own documents and admins to read all
CREATE POLICY "Users can view own documents" ON storage.objects
FOR SELECT USING (
  auth.uid()::text = (storage.foldername(name))[1] OR
  EXISTS (
    SELECT 1 FROM public.users 
    WHERE users.uid = auth.uid()::text 
    AND users.user_type = 'admin'
  )
);
```

## Testing Checklist

- [ ] Renter can access application form
- [ ] Required documents upload successfully
- [ ] Form validation works correctly
- [ ] Application submission creates Firestore document
- [ ] Status page displays correct information
- [ ] Admin can view and review applications
- [ ] Approval process updates user type to 'rentee'
- [ ] Rejection process allows custom feedback
- [ ] Document files are securely stored
- [ ] Navigation flows work correctly
- [ ] Error handling works as expected
- [ ] Responsive design works on different screen sizes

## Future Enhancements

1. **Document OCR**: Automatically extract information from uploaded documents
2. **Email Notifications**: Send email updates on application status changes
3. **Document Expiry Tracking**: Track document expiration dates
4. **Bulk Admin Actions**: Allow admins to process multiple applications
5. **Advanced Search/Filter**: Better filtering options for admins
6. **Application History**: Track all status changes and admin actions
7. **Document Templates**: Provide guidance on required document formats
8. **Integration with Government APIs**: Verify document authenticity

## Conclusion

The Owner Application feature provides a comprehensive solution for renters to apply for owner status by uploading required vehicle documents. The implementation includes secure document storage, admin review processes, and a user-friendly interface that guides applicants through the entire process.