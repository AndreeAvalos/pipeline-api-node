# Api NODE JS
Este es una api de prueba para Kubernetes más Rancher para implementar un Pipeline básico

### Pre-requisitos 📋
1. Conocimientos en Docker
2. Servidor rancher en cualquier plataforma. (LOCAL o NUBE)
3. Tiempo

### Instalación 🔧
1. Crear Archivo .rancher-pipeline.yml 
```
nano .rancher-pipeline.yml
```
```
stages:
- name: Crear Imagen
  steps:
  - publishImageConfig:
      dockerfilePath: ./Dockerfile
      buildContext: .
      tag: andreeavalos/pipeline-api
      pushRemote: true
      registry: index.docker.io
- name: Crear en k8s
  steps:
  - applyYamlConfig:
      path: ./deployment.yaml
timeout: 60
notification: {}
```
2. Crear Archivo deployment.yaml
```
nano deployment.yaml
```
```
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: api-node
  namespace: entrega-final
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      workload.user.cattle.io/workloadselector: deployment-entrega-final-api-node
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
  template:
    metadata:
      labels:
        workload.user.cattle.io/workloadselector: deployment-entrega-final-api-node
    spec:
      containers:
      - image: node
        imagePullPolicy: Always
        name: api-node
      dnsPolicy: ClusterFirst
      imagePullSecrets:
      - name: dockerhub
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
---      
apiVersion: v1
kind: Service
metadata:
  annotations:
    field.cattle.io/targetWorkloadIds: '["deployment:entrega-final:api-node"]'
    workload.cattle.io/targetWorkloadIdNoop: "true"
    workload.cattle.io/workloadPortBased: "true"
  labels:
    cattle.io/creator: norman
  name: api-loadbalancer
  namespace: entrega-final
spec:
  externalTrafficPolicy: Cluster
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    workload.user.cattle.io/workloadselector: deployment-entrega-final-api-node
  type: LoadBalancer
```
3. Crear Dockerfile
```
FROM node
WORKDIR /app
ADD . /app
COPY package.json .
COPY index.js .
RUN npm install --quiet
RUN npm i express
RUN npm  install mysql
ENV PORT 3000
ENV IP "172.17.0.3"
```
4. Crear index.js
```
'use strict';
const express = require('express');
// App
const app = express();
var ip = process.env.IP || '172.17.0.2';
var h = process.env.HOST ||'172.17.0.3';
// Constants
const PORT = 3000;
const HOST = h;

var body_parser = require('body-parser').json();

const mysql = require('mysql');
// connection configurations
const mc = mysql.createConnection({
    host: ip,
    user: 'root',
    password: '1234',
    database: 'bd_p1'
});
mc.connect();



app.get('/viewAlumno', (req, res) => {
	mc.query("Select * from Alumno",function (err, result, fields) {
    if (err) {throw err;}
    else{
    	res.send(result);	
	}
	});
});


app.post('/insertAlumno',body_parser, function (req, res) {

	var dpi = req.body.dpi || '';
    var carnet = req.body.carnet || '';
    var nombre = req.body.nombre || '';
    var apellido = req.body.apellido || '';
    var email = req.body.email || '';
    var telefono = req.body.telefono || ''; 

	var query = 'insert into Alumno(carnet,dpi,nombre,apellido,email,telefono) values('+carnet+','+dpi+',"'+nombre+'","'+apellido+'","'+email+'","'+telefono+'");'
  	  mc.query(query, function (err, result) {
    if (err){res.send("FAIL!!!!");throw err;}
    else{
    	res.send("SUCCESS");}
  });
})


app.listen(PORT,HOST);
console.log(`Running on http://${HOST}:${PORT}`);
```
5. Crear package.json
```
{
  "name": "app",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "start": "node index.js"
  },
  "author": "Andree",
  "license": "ISC",
  "dependencies": {
    "express": "^4.17.1",
    "mysql": "^2.17.1"
  }
}
```
6. Cada vez que se hace un commit, rancher lo toma automaticamente

* [Sergio Mendez](https://www.youtube.com/watch?v=k4y776PqTwI)-Guia de instalacion de rancher