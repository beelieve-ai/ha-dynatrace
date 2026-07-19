FROM dynatrace/oneagent:latest

RUN microdnf install -y jq util-linux && microdnf clean all

COPY run.sh /
RUN chmod a+x /run.sh

ENTRYPOINT ["/bin/bash", "/run.sh"]
