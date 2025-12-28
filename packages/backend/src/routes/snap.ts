import express from 'express';
import multer from 'multer';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { snapService } from '../services/snapService';
import { logger } from '../utils/logger';

const router = express.Router();

// Configure multer for image uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  },
});

// Upload and process snap
router.post(
  '/upload',
  authenticateToken,
  upload.single('image'),
  async (req: AuthRequest, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: 'No image file provided' });
      }

      if (!req.userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const result = await snapService.processSnap(
        req.userId,
        req.file.buffer,
        req.file.mimetype
      );

      res.json({
        success: true,
        snapId: result.snapId,
        result: result.result,
        vectorSyncStatus: 'completed',
      });
    } catch (error) {
      logger.error('Snap upload error:', error);
      res.status(500).json({
        error: 'Failed to process snap',
        message: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }
);

// Get snap status
router.get('/:snapId/status', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const status = await snapService.getSnapStatus(req.params.snapId, req.userId);

    if (!status) {
      return res.status(404).json({ error: 'Snap not found' });
    }

    res.json(status);
  } catch (error) {
    logger.error('Get snap status error:', error);
    res.status(500).json({ error: 'Failed to get snap status' });
  }
});

export default router;

