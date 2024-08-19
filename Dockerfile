# Use a lightweight base image
FROM alpine:latest

# Install required packages
RUN apk add --no-cache \
    build-base \
    cmake \
    wget \
    boost-dev \
    git \
    gzip \
    bash \
    rsync

# Install HepMC2
WORKDIR /opt
RUN wget http://hepmc.web.cern.ch/hepmc/releases/hepmc2.06.11.tgz && \
    tar -xzf hepmc2.06.11.tgz && \
    cd HepMC-2.06.11 && \
    mkdir build && cd build && \
    cmake .. -Dmomentum:STRING=GEV -Dlength:STRING=MM -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make && make install

# Set the Pythia8 path
ENV PYTHIA8=/usr/local/pythia8312
ENV PYTHIA8DATA=$PYTHIA8/share/Pythia8/xmldoc

# Copy Pythia8 source into the container
COPY ./pythia8312 $PYTHIA8

# Build Pythia8
WORKDIR $PYTHIA8
RUN ./configure --enable-shared --with-hepmc2=/usr/local && \
    make && make install

# Copy suep_generator files to the Pythia directory
WORKDIR $PYTHIA8/SUEP
COPY ./suep_generator/* .

# Modify Makefile to include suep_main target
RUN cp $PYTHIA8/examples/Makefile ./Makefile && \
    sed -i '/^all:/i suep_main: suep_main.cxx DecayToSUEP.cxx suep_shower.cxx $(PREFIX_LIB)/libpythia8.a' Makefile && \
    sed -i '/^suep_main:/a ifeq ($(HEPMC2_USE),true)' Makefile && \
    sed -i '/^ifeq ($(HEPMC2_USE),true)/a\\
\t$(CXX) suep_main.cxx DecayToSUEP.cxx suep_shower.cxx -o suep_main $(CXX_COMMON) \\\n\t-I$(HEPMC2_INCLUDE) -L$(HEPMC2_LIB) -Wl,-rpath,$(HEPMC2_LIB) -lHepMC \\\n\t$(GZIP_INC) $(GZIP_FLAGS)' Makefile && \
    sed -i '/$(GZIP_FLAGS)/a\\
else\n\t@echo "Error: suep_main requires HEPMC2"\nendif' Makefile && \
    cat Makefile

# Replace paths in Makefile.inc
RUN sed -i 's|/afs/cern.ch/work/b/bmaier/public/xMaurizio/pythia/pythia8244/|/usr/local/pythia8312/|g' Makefile.inc

# Ensure the use of local g++
RUN sed -i 's|CXX=/cvmfs/sft.cern.ch/lcg/releases/gcc/8.3.0-cebb0/x86_64-centos7/bin/g++|CXX=g++|' Makefile.inc

# Build the suep_main program
RUN make suep_main

# Set the entry point
ENTRYPOINT ["./suep_main"]