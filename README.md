kadaster-gds2
=============

JAX-WS classes voor benaderen van de Generieke Download Service 2 van het Kadaster. 

[![Maven build](https://github.com/B3Partners/kadaster-gds2/actions/workflows/maven.yml/badge.svg)](https://github.com/B3Partners/kadaster-gds2/actions/workflows/maven.yml)

## Schemas

De bestanden in de schemas/ directory zijn afkomstig van het Kadaster.

## Maken keystore met PKIoverheid certificaat

Je hebt een PKIoverheid certificaat nodig waarvan het publieke deel bij Kadaster bekend is. 
Hiermee word je geauthenticeerd en aan de juiste afgiftes gekoppeld aan de serverkant bij Kadaster.

Dit certificaat moet worden geimporteerd in een keystore (src/main/resources/gds2_key.jks). 
Uitgaande van PEM encoded certificaat en key, doe als volgt:

Maken PKCS12 bestand met certificaat en key. Verifieert ook dat key en certificaat overeenkomen.
`openssl pkcs12 -export -out mycert.p12 -inkey mykey.key -in mycert.crt -name mycert`

Importeren in keystore:
`keytool -importkeystore -destkeystore src/main/resources/gds2_key.jks -srckeystore mycert.p12 -srcstoretype pkcs12 -alias mycert`

Gebruik als wachtwoord "changeit".


## GDS2 listing tool

Zorg dat naast de jar file een bestand `private.key` en een bestand `public.key` met de juiste inhoud (public certificate 
en private key) staan.

```
mvn clean install
mvn dependency:copy-dependencies
java -Dlog4j.configuration=target/test-classes/log4j.xml -cp `ls target/*-SNAPSHOT.jar`:./target/lib/* nl.b3p.gds2.Main2
```

Als alternatief kun je een keystore file opgeven `gds2_key.jks` en any commandline argument 

Gebruik voor SSL debugging de optie `-Djavax.net.debug=all`.

## release maken


```
cd /tmp
git clone git@github.com:B3Partners/kadaster-gds2.git
cd kadaster-gds2
mvn release:prepare -l rel-prepare.log -DdevelopmentVersion=1.3-SNAPSHOT -DreleaseVersion=1.2 -Dtag=v1.2 -T1
mvn release:perform -l rel-perform.log
```

