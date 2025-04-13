const mongoose = require('mongoose');
// * require('mongoose-int32'); Do this only if int32 is really needed for storage constraints

const Schema = mongoose.Schema

// TODO: Recheck districts 1, 3, and 4 to see if the right barangays were obtained from image recognition.
const barangays = {
  '1st District': [
    'Bagong Pag-asa',
    'Bahay Toro',
    'Alicia',
    'Bungad',
    'Project 6',
    'Vasra',
    'Phil-Am',
    'San Antonio',
    'Sto. Cristo',
    'Ramon Magsaysay'
  ],
  '2nd District': [
    'Bagong Silangan',
    'Batasan Hills',
    'Commonwealth',
    'Holy Spirit',
    'Payatas'
  ],
  '3rd District': [
    'Amihan',
    'Bagumbuhay',
    'Bayanihan',
    'Blue Ridge A',
    'Blue Ridge B',
    'Duyan-Duyan',
    'E. Rodriguez',
    'East Kamias',
    'Escopa I',
    'Escopa II',
    'Escopa III',
    'Escopa IV',
    'Libis',
    'Loyola Heights',
    'Mangga',
    'Marilag',
    'Masagana',
    'Matandang Balara',
    'Pansol',
    'Quirino 2-A',
    'Quirino 2-B',
    'Quirino 2-C',
    'Quirino 3-A',
    'San Roque',
    'Silangan',
    'St. Ignatius',
    'Tagumpay',
    'Villa Maria Clara',
    'West Kamias',
    'White Plains'
  ],
  '4th District': [
    'Bagumbayan',
    'Bagong Lipunan Crame',
    'Camp Aguinaldo',
    'Claro',
    'Damar',
    'Damayang Lagi',
    'Del Monte',
    'Don Manuel',
    'Dona Aurora',
    'Dona Imelda',
    'Dona Josefa',
    'Horseshoe',
    'Immaculate Concepcion',
    'Kalusugan',
    'Kaunlaran',
    'Kristong Hari',
    'Laging Handa',
    'Mariana',
    'N.S. Amoranto',
    'Obrero',
    'Paligsahan',
    'Pinagkaisahan',
    'Roxas',
    'Sacred Heart',
    'San Isidro Galas',
    'San Martin de Porres',
    'San Vicente',
    'Santol',
    'Santo Domingo',
    'Santo Nino',
    'Sikatuna Village',
    'South Triangle',
    'Tatalon',
    'Teachers Village East',
    'Teachers Village West',
    'Ugong Norte',
    'Valencia'
  ],
  '5th District': [
    'Bagbag',
    'Capri',
    'Fairview',
    'Greater Lagro',
    'Gulod',
    'Kaligayahan',
    'Nagkaisang Nayon',
    'North Fairview',
    'Novaliches Proper',
    'Pasong Putik Proper',
    'San Agustin',
    'San Bartolome',
    'Santa Monica',
    'Santa Lucia',
    'Sauyo'
  ],
  '6th District': [
    'Apolonio Samson',
    'Baesa',
    'Balon Bato',
    'Culiat',
    'New Era',
    'Pasong Tamo',
    'Sangandaan',
    'Tandang Sora',
    'Unang Sigaw'
],
};
const reportSchema = new Schema({
  // ! For now, Report ID is commented out, need to think of a better way for IDs management
  // report_id: {
  //   type: String,
  //   required: true,
  // },
  district: {
    type: String,
    required: true,
    enum: Object.keys(barangays)
  },
  barangay: {
    type: String,
    required: true,
    validate: {
      validator: function(value) {
        console.log("Validating barangay:", value);
        console.log("District:", this.district);
        console.log("Valid sublevels for this type:", barangays[this.district]);

        if (!this.district) {
          console.error("🚨 ERROR: `this.district` is undefined!");
        }
        
        return barangays[this.district]?.includes(value);
      },
      message: (props) => `${props.value} is not a valid barangay for district ${props.instance.district}`
    }
  },
  specific_location: {
    type: String,
    required: true,
  },
  // ! Changed date to date_and_time para isahan na lang yung date and time retrieval
  date_and_time: {
    type: Date,
    required: true,
  },
  report_type: { 
    type: String, 
    required: true,
    enum: ["Breeding Site", "Suspected Case", "Standing Water", "Infestation"] 
  },
  description: { type: String },
  images: [{ type: String }],
  status: { 
    type: String, 
    default: "Pending", 
    enum: ["Pending", "Rejected", "Validated"]
  },
},{ timestamps: true });

module.exports = mongoose.model('Report', reportSchema);