## gows

- [server](./main.go)  
- [client](./client/client.go)

```
## ACI

make azure-rg
make azure-aci

make azure-aci-fqdn
wsserver-b063757.westeurope.azurecontainer.io


## client (nothing fancy, just connect)

./client -addr wsserver-b063757.westeurope.azurecontainer.io -port 80
```