// Sample doctor dataset — the single source of truth for the `doctors`
// collection schema that the app reads (see lib/core/entities/doctor.dart):
//   name, specialty, bio, rating, clinicAddress, photoUrl.
//
// photoUrl is intentionally absent here: the seed script uploads a generated
// avatar to Storage and fills the URL at write time.
//
// IDs are STABLE and human-readable on purpose — the seed uses set() with
// these ids, so re-running overwrites in place (idempotent, no duplicates).
// Changing an id would orphan that doctor's slots and appointments, so treat
// them as a public contract.
module.exports = [
  {
    id: 'dr-ana-patel',
    name: 'Dr. Ana Patel',
    specialty: 'Cardiology',
    rating: 4.8,
    clinicAddress: '12 Medical Ave, Building 3',
    bio: 'Cardiologist with 15 years of experience in preventive cardiology and heart failure management.',
  },
  {
    id: 'dr-omar-haddad',
    name: 'Dr. Omar Haddad',
    specialty: 'Dermatology',
    rating: 4.5,
    clinicAddress: '8 Health Street, Floor 2',
    bio: 'Specialist in clinical and aesthetic dermatology, with a focus on eczema and psoriasis care.',
  },
  {
    id: 'dr-leila-hassan',
    name: 'Dr. Leila Hassan',
    specialty: 'Pediatrics',
    rating: 4.9,
    clinicAddress: '3 Children Way, Clinic 1',
    bio: 'Pediatrician caring for newborns through adolescents, with 12 years in community clinics.',
  },
  {
    id: 'dr-karim-nasr',
    name: 'Dr. Karim Nasr',
    specialty: 'Orthopedics',
    rating: 4.6,
    clinicAddress: '45 Wellness Blvd, Suite 7',
    bio: 'Orthopedic surgeon focused on sports injuries and minimally invasive joint procedures.',
  },
  {
    id: 'dr-nora-ali',
    name: 'Dr. Nora Ali',
    specialty: 'Neurology',
    rating: 4.7,
    clinicAddress: '20 Brain Research Park, Tower B',
    bio: 'Neurologist specializing in migraine management and epilepsy, with a research background.',
  },
  {
    id: 'dr-sami-khalil',
    name: 'Dr. Sami Khalil',
    specialty: 'General Practice',
    rating: 4.4,
    clinicAddress: '5 Family Care Rd, Ground Floor',
    bio: 'Family physician providing comprehensive primary care for all ages.',
  },
  {
    id: 'dr-maya-saleh',
    name: 'Dr. Maya Saleh',
    specialty: 'Ophthalmology',
    rating: 4.7,
    clinicAddress: '11 Vision Tower, Floor 4',
    bio: 'Ophthalmologist with expertise in cataract surgery and pediatric eye care.',
  },
  {
    id: 'dr-hadi-farid',
    name: 'Dr. Hadi Farid',
    specialty: 'ENT',
    rating: 4.3,
    clinicAddress: '27 Ear Nose Throat Plaza, Suite 2',
    bio: 'ENT surgeon treating hearing loss, sinus conditions, and voice disorders.',
  },
];
