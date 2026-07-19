FROM dynatrace/oneagent:latest

# tar/gzip: the installer "deploys to the host" — which here is this
# container's own fs — and self-extracts with tar there.
RUN microdnf install -y jq util-linux tar gzip && microdnf clean all

COPY run.sh /
RUN chmod a+x /run.sh

ENTRYPOINT ["/bin/bash", "/run.sh"]
