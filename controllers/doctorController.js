const jwt = require("jsonwebtoken");
const asyncHandler = require("express-async-handler");
const bcrypt = require('bcryptjs');
const { Doctor, validateCreateDoctor ,validateUpdateDoctor} = require('../models/Doctor');
const sendEmail = require("../middlewares/email");
/**
 * @desc Register a new admin
 * @route /api/admins/register
 * @method POST
 * @access public
 */
module.exports.registerAdmin = asyncHandler(async (req, res, next) => {
    const { fullName, email, password_hash, phone } = req.body;

    if (!fullName || !email || !password_hash || !phone) {
        return res.status(400).json({ message: "All fields are required" });
    }

    let admin = await Doctor.findOne({ email });
    if (admin) {
        return res.status(400).json({ message: "This email is already registered" });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password_hash, salt);

    admin = new Doctor({
        fullName,
        email,
        password_hash: hashedPassword,
        phone,
        role: "admin", 
    });

    try {
        const result = await admin.save();

        const token = admin.generateToken();

        const { password_hash, ...other } = result._doc;

        res.status(201).json({
            ...other,
            token,
            message: "Admin registered successfully",
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "There was an error registering the admin" });
    }
});

/**
 * @desc Sign up a new doctor
 * @route /api/doctors/register
 * @method POST
 * @access public
 */
module.exports.register = asyncHandler(async (req, res, next) => {
    const { error } = validateCreateDoctor(req.body);
    console.log(req.body);
    if (error) {
        return res.status(400).json({ message: error.details[0].message });
    }

    let doctor = await Doctor.findOne({ email: req.body.email });
    if (doctor) {
        return res.status(400).json({ message: "This email is already registered" });
    }

    doctor = await Doctor.findOne({ licenseNumber: req.body.licenseNumber });
    if (doctor) {
        return res.status(400).json({ message: "This license number is already registered" });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(req.body.password_hash, salt);

    doctor = new Doctor({
        fullName: req.body.fullName,
        image: req.body.image,
        email: req.body.email,
        password_hash: hashedPassword,
        phone: req.body.phone,
        specialization: req.body.specialization,
        licenseNumber: req.body.licenseNumber,
        workplace: {
            name: req.body.workplaceName,
            address: req.body.workplaceAddress || '',
        },
    });

    try {
        const result = await doctor.save();

        const verifyResponse = await module.exports.verifyEmail({ body: { email: doctor.email } }, res, next);
        if (!verifyResponse) {
            return; 
        }

        const token = doctor.generateToken();

        const { password_hash, ...other } = result._doc;

        res.status(201).json({
            ...other,
            token,
            message: "Doctor registered successfully. Please verify your email."
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "There was an error registering the doctor" });
    }
});
/**
 * @desc Get doctor's profile before update
 * @route /api/doctors/profile/:doctorId
 * @method GET
 * @access private (requires authentication)
 */
module.exports.getProfile = asyncHandler(async (req, res, next) => {
    const doctor = await Doctor.findById(req.params.doctorId);
    if (!doctor) {
        return res.status(404).json({ message: "Doctor not found" });
    }

    const { password_hash, ...doctorData } = doctor._doc;

    res.status(200).json({
        message: "Doctor profile fetched successfully",
        doctor: doctorData,
    });
});

/**
 * @desc Change doctor's password
 * @route PUT /api/doctors/change-password
 * @method PUT
 * @access Private (requires authentication)
 */
module.exports.changePassword = asyncHandler(async (req, res) => {
    const { oldPassword, newPassword, confirmPassword } = req.body;
console.log(oldPassword);
    if (!oldPassword || !newPassword || !confirmPassword) {
        return res.status(400).json({ message: 'All fields are required' });
    }

    if (newPassword !== confirmPassword) {
        return res.status(400).json({ message: 'New passwords do not match' });
    }

    const doctorId = req.user.id; 
    const doctor = await Doctor.findById(doctorId);

    if (!doctor) {
        return res.status(404).json({ message: 'Doctor not found' });
    }

    const isPasswordMatch = await bcrypt.compare(oldPassword, doctor.password_hash);
    if (!isPasswordMatch) {
        return res.status(400).json({ message: 'Old password is incorrect' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    doctor.password_hash = hashedPassword;
    await doctor.save();

    res.status(200).json({ message: 'Password changed successfully' });
});

/**
 * @desc Update doctor's profile
 * @route /api/doctors/update/:doctorId
 * @method PUT
 * @access private (requires authentication)
 */
module.exports.updateProfile = asyncHandler(async (req, res, next) => {
    console.log(req.body);
    const { error } = validateUpdateDoctor(req.body);
    if (error) {
        return res.status(400).json({ message: error.details[0].message });
    }

    const doctor = await Doctor.findById(req.params.doctorId);
    if (!doctor) {
        return res.status(404).json({ message: "Doctor not found" });
    }

    if (req.body.email && req.body.email !== doctor.email) {
        const emailExists = await Doctor.findOne({ email: req.body.email });
        if (emailExists) {
            return res.status(400).json({ message: "This email is already registered" });
        }
    }

    if (req.body.licenseNumber && req.body.licenseNumber !== doctor.licenseNumber) {
        const licenseExists = await Doctor.findOne({ licenseNumber: req.body.licenseNumber });
        if (licenseExists) {
            return res.status(400).json({ message: "This license number is already registered" });
        }
    }

    doctor.fullName = req.body.fullName || doctor.fullName;
    doctor.image = req.body.image || doctor.image;
    doctor.about = req.body.about || doctor.about;

    
    doctor.email = req.body.email || doctor.email;
    doctor.phone = req.body.phone || doctor.phone;
    doctor.specialization = req.body.specialization || doctor.specialization;
    doctor.licenseNumber = req.body.licenseNumber || doctor.licenseNumber;
    doctor.workplace.name = req.body.workplaceName || doctor.workplace.name;
    doctor.workplace.address = req.body.workplaceAddress || doctor.workplace.address;

    try {
        const updatedDoctor = await doctor.save();

        const { password_hash, ...updatedData } = updatedDoctor._doc;

        res.status(200).json({
            message: "Doctor profile updated successfully",
            doctor: updatedData,
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "There was an error updating the profile" });
    }
});

/**
 * @desc Verify Email for Doctor
 * @route /api/doctors/verifyemail
 * @method POST
 * @access public
 */
module.exports.verifyEmail = asyncHandler(async (req, res, next) => {
    const { email } = req.body;

    const doctor = await Doctor.findOne({ email });
    if (!doctor) {
        return next(new CustomError('Email not found', 404));
    }

    const verificationCode = Math.floor(1000 + Math.random() * 9000).toString();

    doctor.verificationCode = verificationCode;
    doctor.verificationCodeExpires = Date.now() + 10 * 60 * 1000; // 10 minutes expiration
    await doctor.save({ validateBeforeSave: false });

    const message = `Your email verification code is: ${verificationCode}. It will expire in 10 minutes.`;

    try {
        await sendEmail({
            email: doctor.email,
            subject: 'Email Verification Code',
            message,
        });

        res.status(200).json({
            status: 'success',
            message: 'Verification code sent to your email',
        });
    } catch (err) {
        doctor.verificationCode = undefined;
        doctor.verificationCodeExpires = undefined;
        await doctor.save({ validateBeforeSave: false });

        return next(new CustomError('Error sending verification code. Please try again.', 500));
    }
});

/**
 * @desc Get all doctors and their info
 * @route /api/doctors
 * @method GET
 * @access public
 */
module.exports.getAllDoctors = asyncHandler(async (req, res, next) => {
    try {
        const doctors = await Doctor.find().select('-password_hash'); 

        if (!doctors || doctors.length === 0) {
            return res.status(404).json({ message: "No doctors found." });
        }

        res.status(200).json(doctors);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "There was an error retrieving the doctors." });
    }
});







/**
 * @desc get doctor by id
 * @route /api/doctors/:id
 * @method get
 * @access public 
*/
module.exports.getDoctorById=asyncHandler(async(req,res)=>{ 

    const user = await Doctor.findById(req.params.id).populate(); 
    if (user) {
        res.status(200).json(user); 
    }
    else{
        res.status(404).json({ message:"doctor not found"});
    }
});
/**
* @desc get settings by id
* @route /api/doctors/:id/settings
* @method get
* @access public 
*/
module.exports.getSettings=asyncHandler(async(req,res)=>{ 

const user = await Doctor.findById(req.params.id).populate(); 

if (user) {
    const Settings = user.notificationSettings;

    res.status(200).json(Settings); 
}
else{
    res.status(404).json({ message:"doctor not found"});
}
});
/**
* @desc    Update settings by user ID
* @route   /api/doctors/:id/setsetting
* @method  PUT
* @access  public
*/
module.exports.updateSettings = asyncHandler(async (req, res) => {
const userId = req.params.id;

const { reminderNotifications, messageNotifications, requestNotifications } = req.body;

const user = await Doctor.findById(userId);

if (user) {
  user.notificationSettings = {
   // reminders: reminderNotifications !== undefined ? reminderNotifications : user.notificationSettings.reminderNotifications,
    messages: messageNotifications !== undefined ? messageNotifications : user.notificationSettings.messageNotifications,
    requests: requestNotifications !== undefined ? requestNotifications : user.notificationSettings.requestNotifications,
  };

  await user.save();

  res.status(200).json({
    message: "Notification settings updated successfully",
    notificationSettings: user.notificationSettings,
  });
} else {
  res.status(404).json({ message: "Doctor not found" });
}
});

