const axios = require('axios');
const findNeighboringBarangays = require('../utils/geoUtils');

const analyzeHotspots = async (params) => {
    try {
        // Call Python backend
        const response = await axios.get(`http://localhost:8000/analyze-hotspots`, {
            params: params
        });
        const { hotspots, analysis } = response.data;

        // Find neighboring barangays
        const neighbors = await findNeighboringBarangays(hotspots);

        // Create analysis entries for neighboring barangays
        const neighborAnalysis = neighbors.map(neighbor => ({
            barangay: neighbor,
            status: 'neighbor',
            risk_level: 'elevated',
            alert: `PROXIMITY ALERT: ${neighbor} is adjacent to dengue hotspot(s)`,
            recommendation: 'Implement preventive measures due to proximity to hotspot areas:\n' +
                '1. Increase surveillance\n' +
                '2. Conduct regular mosquito breeding site inspections\n' +
                '3. Enhance community awareness'
        }));

        return {
            message: 'Hotspot and proximity analysis completed',
            hotspots,
            neighboring_barangays: neighbors,
            analysis: [...analysis, ...neighborAnalysis]
        };
    } catch (error) {
        console.error('Error in hotspot analysis:', error);
        throw new Error('Failed to complete hotspot analysis');
    }
};

module.exports = {
    analyzeHotspots
}; 