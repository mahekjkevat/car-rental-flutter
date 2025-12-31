# 🚗 Gear Go – Car Rental Application (Customer App)

<p align="center">
  <img src="Screenshots/logo.png" alt="Gear Go Logo" width="160"/>
</p>

<p align="center">
  <b>Your Journey Starts Here</b>
</p>

---

## 📱 Overview

**Gear Go** is a modern car rental mobile application built using **Flutter**.  
It allows customers to browse available cars, book rentals, manage bookings, receive notifications, and get personalized recommendations.

The app follows a **production-ready architecture**, separating **data storage** and **image storage** for better scalability and performance.

---

## 🛠️ Tech Stack

- Flutter (Android)
- Firebase Authentication
- Cloud Firestore
- Appwrite Storage
- Firebase Cloud Messaging (FCM)

---

## 🔄 Data Architecture

- **Images**
  - Stored in **Appwrite Storage**
  - Public image URLs saved in **Cloud Firestore**

- **Data**
  - Users, cars, bookings, notifications stored in **Firestore**
  - Real-time data synchronization

---

## ✨ Key Features (Customer Side)

- Secure authentication
- Browse cars by brand & location
- Search & filter vehicles
- Book cars with pickup & return dates
- Rental history & invoices
- AI-based recommendations
- Notification center
- Profile & account management
- Real-time cloud data

---

## 📸 App Screenshots

### 🚀 Core Screens

| | | |
|---|---|---|
| ![](Screenshots/01_splash_update_prompt.jpg) | ![](Screenshots/02_welcome_back.jpg) | ![](Screenshots/03_search_home.jpg) |
| Splash & Update | Welcome | Home / Search |

| | | |
|---|---|---|
| ![](Screenshots/04_my_bookings_list.jpg) | ![](Screenshots/05_ai_recommendations.jpg) | ![](Screenshots/06_notification_centre.jpg) |
| My Bookings | AI Recommendations | Notifications |

| | | |
|---|---|---|
| ![](Screenshots/07_user_profile.jpg) | ![](Screenshots/08_about_geargo.jpg) | ![](Screenshots/09_all_brands_grid.jpg) |
| Profile | About App | All Brands |

---

### 🔍 Advanced Screens

| | | |
|---|---|---|
| ![](Screenshots/10_search_filter_sheet.jpg) | ![](Screenshots/11_ford_explorer_card.jpg) | ![](Screenshots/12_car_details_gallery.jpg) |
| Filters | Car Card | Gallery |

| | | |
|---|---|---|
| ![](Screenshots/13_rental_agreement.jpg) | ![](Screenshots/14_pending_booking_tile.jpg) | ![](Screenshots/15_payment_pending.jpg) |
| Agreement | Pending Booking | Payment Pending |

| | | |
|---|---|---|
| ![](Screenshots/16_completed_badge.jpg) | ![](Screenshots/17_invoice_options.jpg) | ![](Screenshots/18_damage_report_form.jpg) |
| Completed | Invoice Options | Damage Report |

| | | |
|---|---|---|
| ![](Screenshots/19_sample_invoice_pdf.jpg) | ![](Screenshots/20_add_car_entry.jpg) | ![](Screenshots/23_login_security_mail.jpg) |
| Invoice PDF | Add Car | Security Mail |

---

## 📌 Notes

- Firebase config files are excluded for security.
- This repository contains **only the customer app (gear_go)**.
- Images are stored in **Appwrite Storage**, URLs saved in Firestore.

---

## 👨‍💻 Author

**Mahek**  
Flutter Developer | Firebase | Appwrite
