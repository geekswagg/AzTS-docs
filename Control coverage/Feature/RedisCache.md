# RedisCache

**Resource Type:** Microsoft.Cache/Redis 

___ 

## Azure_RedisCache_DP_Use_SSL_Port 

### DisplayName 
Non-SSL port must not be enabled 

### Rationale 
Use of HTTPS ensures server/service authentication and protects data in transit from network layer man-in-the-middle, eavesdropping, session-hijacking attacks. 

### Control Spec 

> **Passed:** 
> Non-SSL port is not enabled for Redis Cache
> 
> **Failed:** 
> Non-SSL port is enabled for Redis Cache
> 

### Recommendation 

- **PowerShell** 

	 ```powershell 
	 # To disable Non-SSL port for Redis Cache, run command:
	 Set-AzRedisCache -ResourceGroupName <String> -Name <String> -EnableNonSslPort $false
	 ```  

### Azure Policy or ARM API used for evaluation 

- ARM API to get all Redis caches in the specified subscription: - /subscriptions/{subscriptionId}/providers/Microsoft.Cache/Redis?api-version=2018-03-01 <br />
**Properties:** properties.enableNonSslPort<br />

<br />

___ 

## Azure_RedisCache_DP_Use_Secure_TLS_Version 

### DisplayName 
Use approved version of TLS for Azure RedisCache 

### Rationale 
TLS provides privacy and data integrity between client and server. Using approved TLS version significantly reduces risks from security design issues and security bugs that may be present in older versions. 

### Control Spec 

> **Passed:** 
> Minimum TLS version set to 1.2
> 
> **Failed:** 
> Minimum TLS version set to 1.0 or 1.1
> 
> **Verify:** 
> Minimum TLS version not set (default TLS version can be 1.0 or 1.2 based on when it was created, https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-remove-tls-10-11)
> 

### Recommendation 

- **Azure Portal** 

	 Go to Azure Portal --> your Redis Cache instance --> Settings --> Advanced Settings --> Set Minimum TLS version to '1.2' 

### Azure Policy or ARM API used for evaluation 

- ARM API to get all Redis caches in the specified subscription: - /subscriptions/{subscriptionId}/providers/Microsoft.Cache/Redis?api-version=2018-03-01 <br />
**Properties:** properties.minimumTlsVersion<br />

<br />

___ 

