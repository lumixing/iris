size_t strlen(char *str) {
	size_t len = 0;
	while (*str) {
		len++;
		str++;
	}
	return len;
}

bool streq(char *str1, char *str2) {
	while (*str1 != 0 && *str2 != 0) {
		if (*str1 != *str2)
			return false;
		str1++;
		str2++;
	}
	return *str1 == *str2;
}

int arrsum(int *nums, size_t nums_len) {
	int sum = 0;

	/*
	for (size_t i = 0; i < nums_len; i++) {
		sum += nums[i];
	}
	*/

	size_t i = 0;
	while (i < nums_len) {
		sum += nums[i];
		i++;
	}

	return sum;
}