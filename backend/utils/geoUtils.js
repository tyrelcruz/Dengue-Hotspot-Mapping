const booleanTouches = require('@turf/boolean-touches').default;
const fs = require('fs').promises;
const path = require('path');

/**
 * Gets a simplified boundary description for debugging
 * @param {Object} feature - GeoJSON feature
 * @returns {Object} Simplified boundary info
 */
const getBoundaryInfo = (feature) => {
    const coords = feature.geometry.coordinates[0]; // Get outer ring
    const bounds = {
        north: -90,
        south: 90,
        east: -180,
        west: 180
    };

    // Find bounding box
    coords.forEach(coord => {
        bounds.north = Math.max(bounds.north, coord[1]);
        bounds.south = Math.min(bounds.south, coord[1]);
        bounds.east = Math.max(bounds.east, coord[0]);
        bounds.west = Math.min(bounds.west, coord[0]);
    });

    return {
        name: feature.properties.name,
        bounds,
        numPoints: coords.length
    };
};

/**
 * Checks if two points have the same coordinates
 * @param {Array} point1 - [longitude, latitude]
 * @param {Array} point2 - [longitude, latitude]
 * @returns {boolean}
 */
const arePointsEqual = (point1, point2) => {
    return point1[0] === point2[0] && point1[1] === point2[1];
};

/**
 * Ensures a polygon's rings are properly closed (first and last points are the same)
 * @param {Object} feature - GeoJSON feature
 * @returns {Object} Fixed GeoJSON feature
 */
const ensureClosedPolygon = (feature) => {
    if (feature.geometry.type !== 'Polygon') return feature;

    const coordinates = feature.geometry.coordinates;
    const fixedCoordinates = coordinates.map(ring => {
        if (!arePointsEqual(ring[0], ring[ring.length - 1])) {
            return [...ring, ring[0]];
        }
        return ring;
    });

    return {
        ...feature,
        geometry: {
            ...feature.geometry,
            coordinates: fixedCoordinates
        }
    };
};

/**
 * Checks if two features share a meaningful boundary (at least 2 points)
 * @param {Object} feature1 - First GeoJSON feature
 * @param {Object} feature2 - Second GeoJSON feature
 * @returns {boolean} True if features share a meaningful boundary
 */
const hasSharedBoundary = (feature1, feature2) => {
    const touches = booleanTouches(feature1, feature2);
    if (!touches) return false;

    const coords1 = feature1.geometry.coordinates[0];
    const coords2 = feature2.geometry.coordinates[0];

    let sharedPoints = 0;
    for (let i = 0; i < coords1.length; i++) {
        for (let j = 0; j < coords2.length; j++) {
            if (arePointsEqual(coords1[i], coords2[j])) {
                sharedPoints++;
                if (sharedPoints >= 2) return true; // Early exit if we found enough shared points
            }
        }
    }

    return false;
};

/**
 * Finds all neighboring barangays for given target barangays
 * @param {string[]} targetBarangays - Array of barangay names to find neighbors for
 * @returns {Promise<string[]>} Array of neighboring barangay names
 */
const findNeighboringBarangays = async (targetBarangays) => {
    try {
        const geoJSONPath = path.join(__dirname, '../data/barangays.json');
        const geoJSONData = JSON.parse(await fs.readFile(geoJSONPath, 'utf8'));

        const neighbors = new Set();
        const targetFeatures = [];

        // Find and fix target barangay features
        for (const feature of geoJSONData.features) {
            if (feature.geometry.type !== 'Polygon') continue;
            
            const barangayName = feature.properties.name;
            if (targetBarangays.includes(barangayName)) {
                targetFeatures.push(ensureClosedPolygon(feature));
            }
        }

        // Find neighbors for each target barangay
        for (const targetFeature of targetFeatures) {
            for (const feature of geoJSONData.features) {
                if (feature.geometry.type !== 'Polygon') continue;

                const featureName = feature.properties.name;
                
                if (featureName === targetFeature.properties.name ||
                    targetBarangays.includes(featureName)) {
                    continue;
                }

                try {
                    const fixedFeature = ensureClosedPolygon(feature);
                    if (hasSharedBoundary(targetFeature, fixedFeature)) {
                        neighbors.add(featureName);
                    }
                } catch (error) {
                    console.warn(`Warning: Could not check intersection for barangay ${featureName}:`, error.message);
                    continue;
                }
            }
        }

        return Array.from(neighbors);
    } catch (error) {
        console.error('Error finding neighboring barangays:', error);
        throw new Error('Failed to analyze neighboring barangays');
    }
};

module.exports = findNeighboringBarangays; 