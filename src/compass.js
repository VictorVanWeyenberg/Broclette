const canvas = document.createElement('canvas');
canvas.id = 'cvs';
document.getElementById('compass').insertAdjacentElement('afterend', canvas);

const cvs = document.getElementById("cvs");
cvs.style.margin = "0px";
cvs.style.padding = "0px";
cvs.style.display = "block";
cvs.style.width = "100%";
cvs.style.height = "100%";
cvs.parentElement.style.margin = "0px";
cvs.parentElement.style.padding = "0px";

const ctx = cvs.getContext("2d");
const dpr = window.devicePixelRatio || 1;
const rect = cvs.getBoundingClientRect();
cvs.width = rect.width * dpr;
cvs.height = rect.height * dpr;

ctx.setTransform(dpr, 0, 0, dpr, cvs.width / 2, cvs.height / 2);

const WALLIS_LATITUDE = 46.1762;
const WALLIS_LONGITUDE = 7.8046;

function bearingToTarget(coords, orientation) {
  const toRad = deg => deg * Math.PI / 180;
  const toDeg = rad => rad * 180 / Math.PI;

  const myLat = coords.latitude;
  const myLon = coords.longitude;

  const dLon = toRad(myLon - WALLIS_LONGITUDE);
  const lat1 = toRad(myLat);
  const lat2 = toRad(WALLIS_LATITUDE);

  const east  = Math.sin(dLon) * Math.cos(lat2);
  const north = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);

  const absoluteBearing = (toDeg(Math.atan2(north, east)) + 360) % 360;

  return (orientation - absoluteBearing + 360) % 360;
}

function drawCompass(orientation) {
  const swissRed = '#DA291C';
  const armLength = 40;
  const armWidth = armLength / 7 * 6;
  const tipHeight = armWidth / 2; // gives exactly 90° at the point

  ctx.save();
  ctx.rotate((orientation * Math.PI) / 180);

  ctx.fillStyle = swissRed;
  ctx.clearRect(-cvs.width/2, -cvs.height/2, cvs.width, cvs.height)
  ctx.beginPath();

  const topArmTop = -(armWidth / 2 + armLength);

  ctx.moveTo(0, topArmTop - tipHeight);           // tip (centered!)
  ctx.lineTo(armWidth / 2, topArmTop);            // top-right of top arm
  ctx.lineTo(armWidth / 2, -armWidth / 2);        // bottom-right of top arm
  ctx.lineTo(armWidth / 2 + armLength, -armWidth / 2);
  ctx.lineTo(armWidth / 2 + armLength, armWidth / 2);
  ctx.lineTo(armWidth / 2, armWidth / 2);
  ctx.lineTo(armWidth / 2, armWidth / 2 + armLength);
  ctx.lineTo(-armWidth / 2, armWidth / 2 + armLength);
  ctx.lineTo(-armWidth / 2, armWidth / 2);
  ctx.lineTo(-(armWidth / 2 + armLength), armWidth / 2);
  ctx.lineTo(-(armWidth / 2 + armLength), -armWidth / 2);
  ctx.lineTo(-armWidth / 2, -armWidth / 2);       // bottom-left of top arm
  ctx.lineTo(-armWidth / 2, topArmTop);           // top-left of top arm
  ctx.closePath();                                // closes to tip
  ctx.fill();

  ctx.restore();
}

let currentPosition = null;

// GPS: update slowly and independently
navigator.geolocation.watchPosition((position) => {
  currentPosition = position.coords;
}, null, {
  enableHighAccuracy: true,
  maximumAge: 5000,    // accept cached position up to 5s old
  timeout: 10000
});

// Orientation: fires fast, but just uses the last known position
window.addEventListener('deviceorientationabsolute', (e) => {
  if (!currentPosition) return;
  const orientation = bearingToTarget(currentPosition, parseInt(e.alpha));
  drawCompass(orientation);
}, true);

drawCompass(0);