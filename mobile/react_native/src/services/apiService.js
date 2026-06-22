import axios from 'axios';

const BASE_URL = 'http://127.0.0.1:8000';

const healthCheck = async () => {
  try {
    const response = await axios.get(`${BASE_URL}/health`);
    return response.status === 200;
  } catch (error) {
    return false;
  }
};

export default {
  healthCheck,
};
