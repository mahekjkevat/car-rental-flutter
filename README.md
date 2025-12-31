# 🚗 Car Rental Flutter Applications

This repository contains two Flutter applications for a complete car rental system.

---

  [![Flutter](https://img.shields.io/badge/Flutter-3.19-%2302569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
  [![Appwrite](https://img.shields.io/badge/Appwrite-Storage-FD366E?style=for-the-badge&logo=appwrite&logoColor=white)](https://appwrite.io)
  [![Dart](https://img.shields.io/badge/Dart-3.0-%230175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

---
## 📱 Gear Go – Customer Application

<p align="center">
  <img src="gear_go/Screenshots/logo.png" width="160" />
</p>

<p align="center">
  <b>Your Journey Starts Here</b>
</p>

---

## 📖 Overview

**Gear Go** is a customer-facing car rental mobile application built using **Flutter**.  
Users can browse vehicles, make bookings, manage rentals, receive notifications, and view invoices.

The app uses a **scalable cloud architecture** where data and images are handled separately.

---

## 🛠 Tech Stack

- Flutter
- Firebase Authentication
- Cloud Firestore
- Appwrite Storage (for images)
- Firebase Cloud Messaging (FCM)

---

## 🔄 Data Architecture

- **Images**
  - Stored in **Appwrite Storage**
  - Image URLs saved in **Firestore**

- **Data**
  - Users, cars, bookings, notifications stored in **Cloud Firestore**
  - Real-time updates

---

## ✨ Key Features (Customer Side)

- Secure login & authentication
- Browse cars by brand & location
- Search & filter vehicles
- Car booking & rental management
- AI-based recommendations
- Notification center
- Profile management

---

## 📸 App Screenshots

### 🚀 Core Screens

| | | |
|---|---|---|
| ![](gear_go/Screenshots/01_splash_update_prompt.jpg) | ![](gear_go/Screenshots/02_welcome_back.jpg) | ![](gear_go/Screenshots/03_search_home.jpg) |
| Splash & Update | Welcome | Home |

| | | |
|---|---|---|
| ![](gear_go/Screenshots/04_my_bookings_list.jpg) | ![](gear_go/Screenshots/05_ai_recommendations.jpg) | ![](gear_go/Screenshots/06_notification_centre.jpg) |
| My Bookings | AI Recommendations | Notifications |

| | | |
|---|---|---|
| ![](gear_go/Screenshots/07_user_profile.jpg) | ![](gear_go/Screenshots/08_about_geargo.jpg) | ![](gear_go/Screenshots/09_all_brands_grid.jpg) |
| Profile | About | Brands |

---

### 🔍 Advanced Screens

| | | |
|---|---|---|
| ![](gear_go/Screenshots/10_search_filter_sheet.jpg) | ![](gear_go/Screenshots/11_ford_explorer_card.jpg) | ![](gear_go/Screenshots/12_car_details_gallery.jpg) |
| Filters | Car Card | Gallery |

| | | |
|---|---|---|
| ![](gear_go/Screenshots/13_rental_agreement.jpg) | ![](gear_go/Screenshots/14_pending_booking_tile.jpg) | ![](gear_go/Screenshots/15_payment_pending.jpg) |
| Agreement | Pending | Payment |

| | | |
|---|---|---|
| ![](gear_go/Screenshots/16_completed_badge.jpg) | ![](gear_go/Screenshots/17_invoice_options.jpg) | ![](gear_go/Screenshots/18_damage_report_form.jpg) |
| Completed | Invoice | Damage |

---

## 🛠️ Car Rental Admin – Admin Application

<p align="center">
  <img src="car_rental_admin/Screenshots/logo.png" width="160" />
</p>

<p align="center">
  <b>Manage Cars, Bookings & Customers</b>
</p>

---

## 📖 Admin App Overview

The **Car Rental Admin App** is designed for administrators and car owners to manage the entire rental system efficiently.  
It provides full control over cars, bookings, users, payments, and system notifications.

The admin app works in sync with the customer app using **Cloud Firestore** and **Appwrite Storage**.

---

## 🛠 Admin Tech Stack

- Flutter
- Firebase Authentication
- Cloud Firestore
- Appwrite Storage (for images)
- Firebase Cloud Messaging
- WhatsApp Alerts (Admin notifications)

---

## ✨ Admin Features

- Admin authentication & role-based access
- Add, update & remove cars
- Manage brands & vehicle listings
- View & approve bookings
- Booking status management (Pending / Completed)
- Invoice generation & download
- Damage report handling
- WhatsApp & email alerts
- Real-time dashboard updates

---

## 📸 Admin App Screenshots

### 🚀 Core Admin Screens

| | | |
|---|---|---|
| ![](car_rental_admin/Screenshots/01_splash_update_prompt.jpg) | ![](car_rental_admin/Screenshots/02_welcome_back.jpg) | ![](car_rental_admin/Screenshots/03_search_home.jpg) |
| Splash & Update | Admin Login | Dashboard |

| | | |
|---|---|---|
| ![](car_rental_admin/Screenshots/04_my_bookings_list.jpg) | ![](car_rental_admin/Screenshots/05_ai_recommendations.jpg) | ![](car_rental_admin/Screenshots/06_notification_centre.jpg) |
| Booking List | Smart Insights | Notifications |

| | | |
|---|---|---|
| ![](car_rental_admin/Screenshots/07_user_profile.jpg) | ![](car_rental_admin/Screenshots/08_about_geargo.jpg) | ![](car_rental_admin/Screenshots/09_all_brands_grid.jpg) |
| Admin Profile | About System | All Brands |

---

### 🔍 Admin Management Screens

| | | |
|---|---|---|
| ![](car_rental_admin/Screenshots/10_search_filter_sheet.jpg) | ![](car_rental_admin/Screenshots/11_ford_explorer_card.jpg) | ![](car_rental_admin/Screenshots/12_car_details_gallery.jpg) |
| Advanced Filters | Car Card | Car Gallery |

| | | |
|---|---|---|
| ![](car_rental_admin/Screenshots/13_rental_agreement.jpg) | ![](car_rental_admin/Screenshots/14_pending_booking_tile.jpg) | ![](car_rental_admin/Screenshots/15_payment_pending.jpg) |
| Rental Agreement | Pending Booking | Payment Pending |

| | | |
|---|---|---|
| ![](car_rental_admin/Screenshots/16_completed_badge.jpg) | ![](car_rental_admin/Screenshots/17_invoice_options.jpg) | ![](car_rental_admin/Screenshots/18_damage_report_form.jpg) |
| Completed Booking | Invoice Options | Damage Report |

---

### 📄 Reports & Alerts

| | | |
|---|---|---|
| ![](car_rental_admin/Screenshots/19_sample_invoice_pdf.jpg) | ![](car_rental_admin/Screenshots/20_add_car_entry.jpg) | ![](car_rental_admin/Screenshots/21_admin_whatsapp_alert.jpg) |
| Invoice PDF | Add New Car | WhatsApp Alert |

| | | |
|---|---|---|
| ![](car_rental_admin/Screenshots/22_car_add_whatsapp.jpg) | ![](car_rental_admin/Screenshots/23_login_security_mail.jpg) |  |
| Car Added Alert | Security Email |  |

---


## 👨‍💻 Author

**Mahek**  
Flutter Developer | Firebase | Appwrite
