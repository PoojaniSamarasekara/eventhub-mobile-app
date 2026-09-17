"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.api = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");
admin.initializeApp();
const db = admin.firestore();
const app = express();
app.use(express.json());
// Authentication Token Verification Middleware
const authenticateToken = async (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({ error: "Unauthorized: Missing token header" });
        return;
    }
    const token = authHeader.split("Bearer ")[1];
    try {
        const decodedToken = await admin.auth().verifyIdToken(token);
        const userDoc = await db.collection("users").doc(decodedToken.uid).get();
        const role = userDoc.exists ? userDoc.data()?.role || "user" : "user";
        req.user = {
            uid: decodedToken.uid,
            role: role,
        };
        next();
    }
    catch (error) {
        res.status(401).json({ error: "Unauthorized: Invalid token verification" });
    }
};
// --- EVENTS ENDPOINTS ---
// GET /events - Fetch all events
app.get("/events", async (req, res) => {
    try {
        const snapshot = await db.collection("events").orderBy("dateTime").get();
        const events = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        res.status(200).json(events);
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error reading events" });
    }
});
// GET /events/:id - Fetch single event details
app.get("/events/:id", async (req, res) => {
    try {
        const id = req.params.id;
        const doc = await db.collection("events").doc(id).get();
        if (!doc.exists) {
            res.status(404).json({ error: "Event not found" });
            return;
        }
        res.status(200).json({ id: doc.id, ...doc.data() });
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error fetching event" });
    }
});
// POST /events - Create a new event (Organizer-only)
app.post("/events", authenticateToken, async (req, res) => {
    if (req.user?.role !== "organizer") {
        res.status(403).json({ error: "Forbidden: Organizer role required" });
        return;
    }
    const { name, imageUrl, description, category, dateTime, location, price, totalSeats } = req.body;
    if (!name || !description || !category || !dateTime || !location || price === undefined || totalSeats === undefined) {
        res.status(400).json({ error: "Bad request: Missing or invalid required parameters" });
        return;
    }
    if (price < 0 || totalSeats <= 0) {
        res.status(400).json({ error: "Bad request: Pricing must be positive; capacity must exceed 0" });
        return;
    }
    try {
        const newEvent = {
            organizerId: req.user.uid,
            name,
            imageUrl: imageUrl || "https://placehold.co/600x400/png",
            description,
            category,
            dateTime: admin.firestore.Timestamp.fromDate(new Date(dateTime)),
            location,
            price: Number(price),
            totalSeats: Number(totalSeats),
            seatsAvailable: Number(totalSeats),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        const docRef = await db.collection("events").add(newEvent);
        res.status(201).json({ id: docRef.id, ...newEvent });
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error adding event" });
    }
});
// PUT /events/:id - Update an event (Organizer-only, Owner-only)
app.put("/events/:id", authenticateToken, async (req, res) => {
    if (req.user?.role !== "organizer") {
        res.status(403).json({ error: "Forbidden: Organizer role required" });
        return;
    }
    const { name, imageUrl, description, category, dateTime, location, price, totalSeats } = req.body;
    if (!name || !description || !category || !dateTime || !location || price === undefined || totalSeats === undefined) {
        res.status(400).json({ error: "Bad request: Missing input attributes" });
        return;
    }
    const id = req.params.id;
    const eventRef = db.collection("events").doc(id);
    try {
        const success = await db.runTransaction(async (transaction) => {
            const eventDoc = await transaction.get(eventRef);
            if (!eventDoc.exists) {
                res.status(404).json({ error: "Event not found" });
                return false;
            }
            if (eventDoc.data()?.organizerId !== req.user?.uid) {
                res.status(403).json({ error: "Forbidden: Unauthorized event owner modification" });
                return false;
            }
            const oldTotal = eventDoc.data()?.totalSeats || 0;
            const oldAvailable = eventDoc.data()?.seatsAvailable || 0;
            const bookedSeats = oldTotal - oldAvailable;
            if (totalSeats < bookedSeats) {
                res.status(400).json({ error: `Cannot reduce total seats below already booked seats (${bookedSeats})` });
                return false;
            }
            const newAvailable = totalSeats - bookedSeats;
            transaction.update(eventRef, {
                name,
                imageUrl: imageUrl || "https://placehold.co/600x400/png",
                description,
                category,
                dateTime: admin.firestore.Timestamp.fromDate(new Date(dateTime)),
                location,
                price: Number(price),
                totalSeats: Number(totalSeats),
                seatsAvailable: newAvailable,
            });
            return true;
        });
        if (success) {
            res.status(200).json({ message: "Event updated cleanly" });
        }
    }
    catch (error) {
        res.status(500).json({ error: "Internal transaction failure updating event" });
    }
});
// DELETE /events/:id - Delete event (Organizer-only, Owner-only)
app.delete("/events/:id", authenticateToken, async (req, res) => {
    if (req.user?.role !== "organizer") {
        res.status(403).json({ error: "Forbidden: Organizer role required" });
        return;
    }
    const id = req.params.id;
    const eventRef = db.collection("events").doc(id);
    try {
        const success = await db.runTransaction(async (transaction) => {
            const eventDoc = await transaction.get(eventRef);
            if (!eventDoc.exists) {
                res.status(404).json({ error: "Event not found" });
                return false;
            }
            if (eventDoc.data()?.organizerId !== req.user?.uid) {
                res.status(403).json({ error: "Forbidden: Unauthorized event owner removal" });
                return false;
            }
            transaction.delete(eventRef);
            return true;
        });
        if (success) {
            res.status(200).json({ message: "Event removed cleanly" });
        }
    }
    catch (error) {
        res.status(500).json({ error: "Internal transaction failure deleting event" });
    }
});
// --- BOOKINGS ENDPOINTS ---
// GET /bookings - Fetch logged-in user's bookings
app.get("/bookings", authenticateToken, async (req, res) => {
    try {
        const snapshot = await db.collection("bookings").where("userId", "==", req.user?.uid).get();
        const bookings = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        res.status(200).json(bookings);
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error fetching user bookings" });
    }
});
// POST /bookings - Book seats safely using a Firestore Transaction
app.post("/bookings", authenticateToken, async (req, res) => {
    const { eventId, numberOfSeats, attendeeName, attendeeContact, eventName, eventDateTime, eventLocation, totalPrice } = req.body;
    if (!eventId || !numberOfSeats || !attendeeName || !attendeeContact || !eventName || !eventDateTime || !eventLocation || totalPrice === undefined) {
        res.status(400).json({ error: "Bad request: Missing required booking input parameters" });
        return;
    }
    const eventRef = db.collection("events").doc(eventId);
    const bookingRef = db.collection("bookings").doc();
    const reference = Math.random().toString(36).substring(2, 10).toUpperCase();
    try {
        const result = await db.runTransaction(async (transaction) => {
            const eventDoc = await transaction.get(eventRef);
            if (!eventDoc.exists) {
                res.status(404).json({ error: "Target event not found" });
                return null;
            }
            const available = eventDoc.data()?.seatsAvailable || 0;
            if (available < numberOfSeats) {
                res.status(400).json({ error: "Bad request: Not enough available spaces left" });
                return null;
            }
            transaction.update(eventRef, { seatsAvailable: available - numberOfSeats });
            const newBooking = {
                userId: req.user?.uid,
                eventId,
                numberOfSeats: Number(numberOfSeats),
                status: "confirmed",
                bookingDate: admin.firestore.FieldValue.serverTimestamp(),
                attendeeName,
                attendeeContact,
                bookingReference: reference,
                eventName,
                eventDateTime: admin.firestore.Timestamp.fromDate(new Date(eventDateTime)),
                eventLocation,
                totalPrice: Number(totalPrice),
            };
            transaction.set(bookingRef, newBooking);
            return { id: bookingRef.id, ...newBooking };
        });
        if (result) {
            res.status(201).json(result);
        }
    }
    catch (error) {
        res.status(500).json({ error: "Transaction exception recording booking" });
    }
});
// PUT /bookings/:id/cancel - Cancel a booking safely via transaction
app.put("/bookings/:id/cancel", authenticateToken, async (req, res) => {
    const id = req.params.id;
    const bookingRef = db.collection("bookings").doc(id);
    try {
        const result = await db.runTransaction(async (transaction) => {
            const bookingDoc = await transaction.get(bookingRef);
            if (!bookingDoc.exists) {
                res.status(404).json({ error: "Booking reference match not found" });
                return false;
            }
            const bookingData = bookingDoc.data();
            if (bookingData?.userId !== req.user?.uid) {
                res.status(403).json({ error: "Forbidden: Unauthorized access to cancel booking" });
                return false;
            }
            if (bookingData?.status === "cancelled") {
                res.status(400).json({ error: "Booking already cancelled" });
                return false;
            }
            const eventRef = db.collection("events").doc(bookingData?.eventId);
            const eventDoc = await transaction.get(eventRef);
            if (eventDoc.exists) {
                const available = eventDoc.data()?.seatsAvailable || 0;
                transaction.update(eventRef, { seatsAvailable: available + bookingData?.numberOfSeats });
            }
            transaction.update(bookingRef, { status: "cancelled" });
            return true;
        });
        if (result) {
            res.status(200).json({ message: "Booking cancelled successfully" });
        }
    }
    catch (error) {
        res.status(500).json({ error: "Transaction execution cancellation failure" });
    }
});
exports.api = functions.https.onRequest(app);
//# sourceMappingURL=index.js.map