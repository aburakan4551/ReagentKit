# Gemini AI Image Analysis Setup

This guide explains how to set up and use the new Gemini AI image analysis feature in the reagent testing app.

## Features

### 🔬 AI-Powered Chemical Analysis
- Upload images of chemical tests, reactions, or color changes
- Get AI analysis of detected chemicals and substances
- Receive detailed color analysis and chemical identification

### 🎨 Smart Reagent Recommendation
- AI analyzes uploaded images to recommend the best matching reagent test
- Color-based matching to suggest appropriate reagent tests
- Confidence scoring for recommendations

## Setup Instructions

### 1. Get Google AI API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Create a new API key
4. Copy the API key (keep it secure!)

### 2. Configure API Key ✅ CONFIGURED

Your API key has been securely set up! You have several options to run the app:

#### Option A: VS Code Launch Configuration (Recommended) ✅
Your API key is already configured in `.vscode/launch.json`. Just press F5 to run with debugging.

#### Option B: Use the Helper Script ✅
```bash
./run_with_api_key.sh debug
```

#### Option C: Command Line
```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY
```

**Note**: Your API key `YOUR_API_KEY` has been securely configured using Flutter best practices. The key is loaded from environment variables to keep it secure.

### 3. Install Dependencies

The required dependencies are already added to `pubspec.yaml`:
- `google_generative_ai: ^0.4.6` - Google's Gemini AI SDK
- `image_picker: ^1.1.2` - For camera and gallery access
- `http: ^1.2.1` - For network requests

Run:
```bash
flutter packages get
```

## How to Use

### 1. Access AI Analysis
1. Open the Reagent Testing page
2. Tap the camera icon in the top-right corner to toggle AI analysis
3. The AI Image Analysis widget will appear

### 2. Upload an Image
- **Take Photo**: Use device camera to capture a new image
- **From Gallery**: Select an existing image from device gallery

### 3. Analyze the Image
1. Once image is selected, tap "Analyze Image"
2. Wait for AI processing (usually 3-10 seconds)
3. View the results:
   - **Recommended Reagent**: Best matching test based on visual analysis
   - **Confidence Score**: How confident the AI is in its recommendation
   - **Chemical Analysis**: Detected chemicals and substances
   - **Color Analysis**: Description of significant colors observed

### 4. Navigate to Recommended Test
- Tap on the recommended reagent result to automatically navigate to that test's detail page
- Or manually select any reagent from the main grid

## Supported Models

The app uses **Gemini 2.0 Flash** model, which provides:
- Fast image analysis (typically 3-10 seconds)
- High accuracy for chemical and color detection
- Support for various image formats (JPEG, PNG)
- Optimized for multimodal (text + image) prompts

## Best Practices

### Image Quality
- Use well-lit images with clear visibility of chemicals/reactions
- Avoid blurry or low-resolution photos
- Include reference objects for scale when possible
- Focus on the chemical reaction or color change area

### What Works Best
- pH strips and color indicators
- Chemical color changes and reactions
- Laboratory test results
- Reagent test outcomes
- Solution color comparisons

### Limitations
- AI analysis is assistive, not diagnostic
- Always verify AI recommendations with proper chemical knowledge
- Some complex reactions may require human expertise
- Lighting conditions can affect color analysis accuracy

## Privacy & Security

- Images are sent to Google's Gemini API for analysis
- No images are stored permanently by the app
- API key should be kept secure and not shared
- Consider data privacy requirements for your use case

## Troubleshooting

### "Analysis failed" Error
- Check internet connection
- Verify API key is correct
- Ensure image is not corrupted
- Try with a different image

### "No valid JSON found" Error  
- Usually temporary - try analyzing again
- May indicate API rate limiting
- Check API quota in Google Cloud Console

### Empty/Incorrect Results
- Try with better lighting
- Use higher resolution images
- Focus on the chemical reaction area
- Ensure chemicals/colors are clearly visible

## API Usage & Costs

- Gemini API has free tier with generous limits
- Pay-per-use pricing for higher volumes
- Monitor usage in [Google Cloud Console](https://console.cloud.google.com/)
- Current pricing: Check [Google AI Pricing](https://ai.google.dev/pricing)

## Support

For technical issues:
1. Check this documentation
2. Verify API key setup
3. Test with different images
4. Check network connectivity
5. Review app logs for detailed error messages

---

**Note**: This AI feature is designed to assist with reagent selection and chemical analysis. Always use proper laboratory safety procedures and verify results with appropriate chemical expertise. 