# Issue Ticketing System
# 🛠️ Issue Ticketing System (Flutter + Supabase)

## 📖 Project Description

This project is an **IT/Issue Ticketing System** developed using **Flutter** and **Supabase**, designed specifically for internal office use. The system enables users to report issues and allows admins to manage, track, and respond to those tickets efficiently.

The application features a **role-based login system** — users are redirected to different interfaces based on their roles. If logged in as an admin, the user is taken to an **Admin Panel**; otherwise, they are directed to a **ticket submission form**.

When a user submits a ticket, an **automated email notification** is sent to the admin using **EmailJS**, helping ensure that issues are promptly addressed.

The Admin Panel includes:
- A **dashboard** with stat cards and charts,
- A **ticket management page** to view and update ticket statuses and priorities,
- A **user management section** where admins can assign roles and create new users,
- A **settings page** to update admin account information.

For backend operations, **Supabase** is used. **Row-Level Security (RLS)** is enabled on both `users` and `tickets` tables, ensuring data access is restricted by user roles. **Supabase Auth** handles secure login without any third-party sign-in methods (like Google), prioritizing internal user management.

---

## 🚀 Features

- 🔐 **Role-Based Authentication** using Supabase Auth
  - Admins are redirected to the admin dashboard
  - Users are redirected to the ticket submission form

- 📩 **Ticket Submission with Email Notification**
  - Users submit tickets through a form
  - Admin receives an instant email via EmailJS with ticket details

- 📊 **Admin Dashboard**
  - Stat cards displaying ticket counts by status
  - Bar chart visualizing number of tickets from each department

- 🎫 **Ticket Management**
  - View all tickets submitted
  - Click to view details and update ticket status or priority

- 👥 **User Management (Admin Only)**
  - View all registered users
  - Assign roles (admin or user)
  - Create new users manually (no public signup)

- ⚙️ **Settings Page**
  - Admins can update their name, email, and password

- 🧰 **Supabase Backend**
  - RLS (Row-Level Security) enabled on all critical tables
  - Supabase Auth for secure, role-based login

- ✉️ **EmailJS Integration**
  - Sends automated emails to the admin when a ticket is submitted

---
## 🖼️ ScreenShots

**LOG IN**

<img width="1365" height="719" alt="image" src="https://github.com/user-attachments/assets/19180b3d-a871-4809-8fdc-2b2bbe2d3e73" />

## ADMIN PANEL

**GENERAL**

<img width="1365" height="718" alt="image" src="https://github.com/user-attachments/assets/a4e15642-e4ff-427b-9446-e9c3cd36592d" />

**TICKETS**

<img width="1365" height="720" alt="image" src="https://github.com/user-attachments/assets/6cb47cff-0f4b-44c8-94a3-82037e8ea4ee" />

<img width="1365" height="719" alt="image" src="https://github.com/user-attachments/assets/c42f96f4-582d-4d05-9a85-d0795c85ac63" />

**USER MANAGEMENT**

<img width="1365" height="715" alt="image" src="https://github.com/user-attachments/assets/85e838f5-3d67-448a-8445-7dc7b08a60e3" />

<img width="535" height="587" alt="image" src="https://github.com/user-attachments/assets/8c2e8f21-47c2-4e1a-83e1-4c1292a0599b" />


**REPORTS**

<img width="1365" height="716" alt="image" src="https://github.com/user-attachments/assets/003f23cd-5c41-4690-bd35-383cc079f242" />

<img width="1365" height="719" alt="image" src="https://github.com/user-attachments/assets/330455b9-9944-4a28-a99a-01fd0b3489c7" />

**SETTINGS**

<img width="1365" height="719" alt="image" src="https://github.com/user-attachments/assets/7cc23dc6-e845-439a-a1f4-ba53f7485668" />

<img width="1365" height="718" alt="image" src="https://github.com/user-attachments/assets/290b555d-e551-41ec-8e49-6b2e41c33d2b" />

## USER SCREEN

<img width="1365" height="715" alt="image" src="https://github.com/user-attachments/assets/7822593c-4fcd-4305-bcb1-1bfdf2c67edb" />

**AUTOMATED EMAIL**
<img width="1307" height="590" alt="image" src="https://github.com/user-attachments/assets/22144d7a-f088-4d9a-8616-2e07fab8ec82" />

<img width="1311" height="589" alt="image" src="https://github.com/user-attachments/assets/8e0d015a-f836-4273-b423-b6ea11c05e4e" />

---
## 📦 Installation
To run this project, follow these steps:

## 🔧 Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- A configured [Supabase project](https://supabase.com/)
- An [EmailJS account](https://www.emailjs.com/)
  
1) Clone the repository:
**git clone** https://github.com/shawaiz-kashif/Issue-Ticketing-System.git

2) Navigate to the project directory:
**cd ticket_gen**

3) Install the dependencies:
**flutter pub get**

4) Run the application:
**flutter run**



