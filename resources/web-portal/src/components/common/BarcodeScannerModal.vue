<template>
  <div
    v-if="isOpen"
    class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-slate-900/70 backdrop-blur-sm overflow-hidden"
    @wheel.stop
  >
    <div class="relative bg-white dark:bg-[#111827] w-full max-w-lg rounded-3xl shadow-2xl border border-slate-200/80 dark:border-slate-800/80 overflow-hidden flex flex-col max-h-[90vh] animate-in fade-in zoom-in-95">
      <!-- Header -->
      <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
        <div class="flex items-center gap-2.5">
          <div class="w-8 h-8 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"/></svg>
          </div>
          <div>
            <h3 class="text-sm font-bold text-slate-900 dark:text-white">{{ title || 'Barcode & IMEI Scanner' }}</h3>
            <p class="text-[11px] text-slate-400">Scan box sticker, product barcode, or handheld scanner</p>
          </div>
        </div>
        <button
          type="button"
          @click="close"
          class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition cursor-pointer text-lg p-1"
        >
          ✕
        </button>
      </div>

      <!-- Mode Tabs -->
      <div class="px-6 pt-3 pb-1 border-b border-slate-100 dark:border-slate-800/80 bg-slate-50/30 dark:bg-slate-900/20 flex gap-2 shrink-0">
        <button
          type="button"
          @click="activeMode = 'camera'"
          class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 cursor-pointer"
          :class="[
            activeMode === 'camera'
              ? 'bg-indigo-600 text-white shadow-sm shadow-indigo-600/30'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
          ]"
        >
          <span>📷</span> Camera Scan
        </button>
        <button
          type="button"
          @click="activeMode = 'box'"
          class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 cursor-pointer"
          :class="[
            activeMode === 'box'
              ? 'bg-indigo-600 text-white shadow-sm shadow-indigo-600/30'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
          ]"
        >
          <span>⚡</span> Auto-Scan Box Sticker
        </button>
        <button
          type="button"
          @click="activeMode = 'manual'"
          class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 cursor-pointer"
          :class="[
            activeMode === 'manual'
              ? 'bg-indigo-600 text-white shadow-sm shadow-indigo-600/30'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
          ]"
        >
          <span>⌨️</span> USB / Manual
        </button>
      </div>

      <!-- Body -->
      <div class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1 min-h-0">
        <!-- 1. Live Camera View -->
        <div v-show="activeMode === 'camera'" class="space-y-3">
          <div class="relative w-full aspect-video bg-black rounded-2xl overflow-hidden flex items-center justify-center border border-slate-700 shadow-inner">
            <video
              ref="videoRef"
              autoplay
              playsinline
              muted
              class="w-full h-full object-cover"
            ></video>

            <!-- Viewfinder Overlay -->
            <div class="absolute inset-0 pointer-events-none flex items-center justify-center">
              <div class="w-64 h-36 border-2 border-indigo-400/90 rounded-2xl relative shadow-[0_0_0_9999px_rgba(0,0,0,0.5)]">
                <!-- Laser line -->
                <div class="absolute inset-x-0 top-1/2 h-0.5 bg-rose-500 shadow-[0_0_8px_#f43f5e] animate-pulse"></div>
                <!-- Corner highlights -->
                <div class="absolute -top-1 -left-1 w-4 h-4 border-t-2 border-l-2 border-indigo-400"></div>
                <div class="absolute -top-1 -right-1 w-4 h-4 border-t-2 border-r-2 border-indigo-400"></div>
                <div class="absolute -bottom-1 -left-1 w-4 h-4 border-b-2 border-l-2 border-indigo-400"></div>
                <div class="absolute -bottom-1 -right-1 w-4 h-4 border-b-2 border-r-2 border-indigo-400"></div>
              </div>
            </div>

            <!-- Camera Error or Permission prompt -->
            <div
              v-if="cameraError"
              class="absolute inset-0 bg-slate-900/90 flex flex-col items-center justify-center p-4 text-center text-xs text-rose-300"
            >
              <span class="text-2xl mb-1">⚠️</span>
              <p class="font-bold">{{ cameraError }}</p>
              <button
                type="button"
                @click="startCamera"
                class="mt-3 px-3 py-1.5 rounded-xl bg-indigo-600 text-white font-semibold cursor-pointer"
              >
                Retry Camera Access
              </button>
            </div>
          </div>

          <p class="text-center text-[11px] text-slate-400">
            Point camera at barcode, QR code, or IMEI number on the phone box
          </p>
        </div>

        <!-- 2. Auto-Scan Box Sticker Area -->
        <div v-show="activeMode === 'box'" class="space-y-3">
          <div class="p-3.5 rounded-2xl bg-indigo-50/60 dark:bg-indigo-950/30 border border-indigo-100 dark:border-indigo-900/40 text-xs text-indigo-700 dark:text-indigo-300">
            <p class="font-bold mb-1">⚡ Auto-Detect Both IMEIs & Serial Number</p>
            <p class="text-[11px] opacity-90">
              Paste or scan the full text printed on the phone box label. The system will automatically extract <strong>IMEI 1</strong>, <strong>IMEI 2</strong>, and <strong>Serial Number</strong>.
            </p>
          </div>

          <div>
            <label class="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1">
              Box Sticker Text / 2D Barcode Data
            </label>
            <textarea
              v-model="boxInputText"
              rows="4"
              @input="parseBoxText"
              placeholder="e.g. IMEI 1: 864523051234567&#10;IMEI 2: 864523057654321&#10;S/N: G6TX8912VHM&#10;Apple iPhone 13 128GB Midnight"
              class="w-full px-3.5 py-2.5 rounded-2xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 text-xs font-mono focus:ring-2 focus:ring-indigo-500"
            ></textarea>
          </div>

          <!-- Detected Output Cards -->
          <div v-if="parsedResult.imei1 || parsedResult.imei2 || parsedResult.serialNumber" class="p-3.5 rounded-2xl bg-emerald-50/70 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-900/40 space-y-2">
            <p class="text-xs font-bold text-emerald-800 dark:text-emerald-300 flex items-center gap-1.5">
              <span>✓</span> Successfully Extracted Identifiers:
            </p>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs font-mono">
              <div v-if="parsedResult.imei1" class="p-2 rounded-xl bg-white dark:bg-slate-900 border border-emerald-100 dark:border-emerald-800">
                <span class="text-[10px] text-slate-400 font-sans block">Primary IMEI 1:</span>
                <span class="font-bold text-slate-900 dark:text-white">{{ parsedResult.imei1 }}</span>
              </div>
              <div v-if="parsedResult.imei2" class="p-2 rounded-xl bg-white dark:bg-slate-900 border border-emerald-100 dark:border-emerald-800">
                <span class="text-[10px] text-slate-400 font-sans block">Secondary IMEI 2:</span>
                <span class="font-bold text-slate-900 dark:text-white">{{ parsedResult.imei2 }}</span>
              </div>
              <div v-if="parsedResult.serialNumber" class="p-2 rounded-xl bg-white dark:bg-slate-900 border border-emerald-100 dark:border-emerald-800 sm:col-span-2">
                <span class="text-[10px] text-slate-400 font-sans block">Serial Number:</span>
                <span class="font-bold text-slate-900 dark:text-white">{{ parsedResult.serialNumber }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 3. USB Handheld / Manual Input -->
        <div v-show="activeMode === 'manual'" class="space-y-3">
          <div>
            <label class="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1">
              Scan with USB / Bluetooth Barcode Gun
            </label>
            <div class="relative">
              <input
                ref="manualInputRef"
                v-model="manualCode"
                @keydown.enter.prevent="submitManualCode"
                type="text"
                autofocus
                placeholder="Click here and scan with barcode gun, or type and press Enter..."
                class="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 text-xs font-mono font-bold focus:ring-2 focus:ring-indigo-500"
              />
              <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"/></svg>
              </span>
            </div>
            <p class="text-[10.5px] text-slate-400 mt-1">
              Supports 1D Barcodes, 2D QR Codes, Code 128, EAN-13, and 15-digit IMEI numbers.
            </p>
          </div>
        </div>
      </div>

      <!-- Sticky Footer -->
      <div class="px-6 py-3.5 bg-slate-50/80 dark:bg-slate-900/50 border-t border-slate-100 dark:border-slate-800/80 flex items-center justify-between shrink-0">
        <button
          type="button"
          @click="close"
          class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-200/60 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer"
        >
          Cancel
        </button>

        <button
          v-if="activeMode === 'box'"
          type="button"
          :disabled="!parsedResult.imei1 && !parsedResult.imei2 && !parsedResult.serialNumber"
          @click="applyBoxResult"
          class="px-5 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 rounded-xl shadow-md shadow-emerald-600/20 transition cursor-pointer"
        >
          Apply Extracted Identifiers
        </button>

        <button
          v-else-if="activeMode === 'manual'"
          type="button"
          :disabled="!manualCode.trim()"
          @click="submitManualCode"
          class="px-5 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 rounded-xl shadow-md shadow-indigo-600/20 transition cursor-pointer"
        >
          Use Code
        </button>

        <button
          v-else
          type="button"
          @click="activeMode = 'manual'"
          class="px-4 py-2 text-xs font-bold text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-950/50 rounded-xl"
        >
          Switch to Manual / USB
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, watch, onUnmounted, nextTick } from 'vue';

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
  title: {
    type: String,
    default: 'Scan Barcode or IMEI',
  },
  initialMode: {
    type: String,
    default: 'camera', // 'camera' | 'box' | 'manual'
  },
});

const emit = defineEmits(['close', 'scan', 'box-result']);

const activeMode = ref(props.initialMode || 'camera');
const videoRef = ref(null);
const manualInputRef = ref(null);
const manualCode = ref('');
const boxInputText = ref('');
const cameraError = ref(null);

let stream = null;
let animationFrameId = null;
let barcodeDetector = null;

const parsedResult = reactive({
  imei1: '',
  imei2: '',
  serialNumber: '',
  raw: '',
});

// Sound feedback on successful scan
function playBeep() {
  try {
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(880, audioCtx.currentTime); // A5 note
    gain.gain.setValueAtTime(0.15, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.12);
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    osc.start();
    osc.stop(audioCtx.currentTime + 0.12);
  } catch (_) {}
}

async function startCamera() {
  cameraError.value = null;
  if (!navigator.mediaDevices?.getUserMedia) {
    cameraError.value = 'Camera access is not supported by your browser.';
    activeMode.value = 'manual';
    return;
  }

  try {
    stream = await navigator.mediaDevices.getUserMedia({
      video: {
        facingMode: { ideal: 'environment' },
        width: { ideal: 1280 },
        height: { ideal: 720 },
      },
    });

    if (videoRef.value) {
      videoRef.value.srcObject = stream;
      await videoRef.value.play();
      initBarcodeDetection();
    }
  } catch (err) {
    console.warn('Camera access denied or error:', err);
    cameraError.value = 'Could not access camera. Please allow camera permissions or use USB/Manual scan.';
  }
}

function stopCamera() {
  if (animationFrameId) {
    cancelAnimationFrame(animationFrameId);
    animationFrameId = null;
  }
  if (stream) {
    stream.getTracks().forEach(t => t.stop());
    stream = null;
  }
  if (videoRef.value) {
    videoRef.value.srcObject = null;
  }
}

async function initBarcodeDetection() {
  if ('BarcodeDetector' in window) {
    try {
      barcodeDetector = new window.BarcodeDetector({
        formats: ['qr_code', 'code_128', 'code_39', 'ean_13', 'ean_8', 'upc_a', 'data_matrix'],
      });
      scanLoop();
    } catch (_) {}
  }
}

async function scanLoop() {
  if (!videoRef.value || !barcodeDetector || !props.isOpen || activeMode.value !== 'camera') {
    return;
  }

  try {
    if (videoRef.value.readyState >= 2) {
      const barcodes = await barcodeDetector.detect(videoRef.value);
      if (barcodes && barcodes.length > 0) {
        const raw = barcodes[0].rawValue?.trim();
        if (raw) {
          playBeep();
          stopCamera();
          emit('scan', raw);
          emit('close');
          return;
        }
      }
    }
  } catch (_) {}

  animationFrameId = requestAnimationFrame(scanLoop);
}

// Box sticker parser (Matching Flutter ScannedBoxResult)
function parseBoxText() {
  const text = boxInputText.value || '';
  parsedResult.raw = text;
  parsedResult.imei1 = '';
  parsedResult.imei2 = '';
  parsedResult.serialNumber = '';

  // 1. Match 14-16 digit numbers (IMEIs)
  const imeiMatches = Array.from(text.matchAll(/\b(\d{14,16})\b/g)).map(m => m[1]);
  if (imeiMatches.length > 0) {
    parsedResult.imei1 = imeiMatches[0];
  }
  if (imeiMatches.length > 1 && imeiMatches[1] !== parsedResult.imei1) {
    parsedResult.imei2 = imeiMatches[1];
  }

  // 2. Check for labelled IMEIs e.g. "IMEI 1: 123..." or "IMEI1: 123..."
  const labelIm1 = text.match(/imei\s*1\s*[:=\-\s]+(\d{14,16})/i);
  if (labelIm1) parsedResult.imei1 = labelIm1[1];

  const labelIm2 = text.match(/imei\s*2\s*[:=\-\s]+(\d{14,16})/i);
  if (labelIm2) parsedResult.imei2 = labelIm2[1];

  // 3. Match Serial Number (S/N or Serial)
  const snMatch = text.match(/(?:s\/n|sn|serial(?:\s*no)?)\s*[:=\-\s]+([a-z0-9\-_]{6,20})/i);
  if (snMatch) {
    parsedResult.serialNumber = snMatch[1].trim();
  }
}

function applyBoxResult() {
  playBeep();
  stopCamera();
  emit('box-result', {
    imei1: parsedResult.imei1,
    imei2: parsedResult.imei2,
    serialNumber: parsedResult.serialNumber,
    raw: parsedResult.raw,
  });
  emit('close');
}

function submitManualCode() {
  const val = manualCode.value.trim();
  if (!val) return;
  playBeep();
  stopCamera();
  emit('scan', val);
  emit('close');
}

function close() {
  stopCamera();
  emit('close');
}

watch(() => props.isOpen, (open) => {
  if (open) {
    activeMode.value = props.initialMode || 'camera';
    manualCode.value = '';
    boxInputText.value = '';
    parsedResult.imei1 = '';
    parsedResult.imei2 = '';
    parsedResult.serialNumber = '';
    nextTick(() => {
      if (activeMode.value === 'camera') {
        startCamera();
      } else if (activeMode.value === 'manual' && manualInputRef.value) {
        manualInputRef.value.focus();
      }
    });
  } else {
    stopCamera();
  }
});

watch(activeMode, (mode) => {
  if (mode === 'camera' && props.isOpen) {
    startCamera();
  } else {
    stopCamera();
    if (mode === 'manual') {
      nextTick(() => manualInputRef.value?.focus());
    }
  }
});

onUnmounted(() => {
  stopCamera();
});
</script>
